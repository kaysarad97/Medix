#!/usr/bin/env python3
import json, math, re, sys
from pathlib import Path
import xml.etree.ElementTree as ET

SRC = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).with_name('logo_medix.svg')
OUTDIR = SRC.parent
W = H = 625
FR = 30
IP = 0
OP = 103
VERSION = '5.12.2'
MARGIN = 30.0
TRACE_END = 84.0
FILL_END = 96.0
STROKE_WIDTH_CANVAS = 9.0

num_re = r'[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?'
tok_re = re.compile(r'[A-Za-z]|' + num_re)

def parse_svg_path(d):
    toks = tok_re.findall(d.replace(',', ' '))
    i = 0
    cmd = None
    cur = (0.0, 0.0)
    start = None
    segments = []  # ('C' or 'L', p0, c1, c2, p3); lines have c1/c2 None
    def iscmd(t): return len(t)==1 and t.isalpha()
    def take(n):
        nonlocal i
        vals = list(map(float, toks[i:i+n])); i += n
        if len(vals) != n: raise ValueError('Unexpected end of path')
        return vals
    while i < len(toks):
        if iscmd(toks[i]):
            cmd = toks[i]; i += 1
            if cmd in 'Zz':
                if start is not None and (abs(cur[0]-start[0])>1e-9 or abs(cur[1]-start[1])>1e-9):
                    segments.append(('L', cur, None, None, start))
                    cur = start
                continue
        if cmd is None: raise ValueError('Missing path command')
        if cmd in 'Mm':
            x,y = take(2)
            if cmd == 'm': x += cur[0]; y += cur[1]
            cur = (x,y)
            if start is None: start = cur
            cmd = 'l' if cmd=='m' else 'L'
        elif cmd in 'Ll':
            x,y = take(2)
            if cmd == 'l': x += cur[0]; y += cur[1]
            p3=(x,y); segments.append(('L',cur,None,None,p3)); cur=p3
        elif cmd in 'Cc':
            x1,y1,x2,y2,x3,y3 = take(6)
            if cmd == 'c':
                x1 += cur[0]; y1 += cur[1]
                x2 += cur[0]; y2 += cur[1]
                x3 += cur[0]; y3 += cur[1]
            p1=(x1,y1); p2=(x2,y2); p3=(x3,y3)
            segments.append(('C',cur,p1,p2,p3)); cur=p3
        else:
            raise ValueError(f'Unsupported SVG path command: {cmd}')
    if start is None or not segments: raise ValueError('No path geometry')
    return start, segments

def cubic_point(p0,p1,p2,p3,t):
    u=1-t
    return (u**3*p0[0]+3*u*u*t*p1[0]+3*u*t*t*p2[0]+t**3*p3[0],
            u**3*p0[1]+3*u*u*t*p1[1]+3*u*t*t*p2[1]+t**3*p3[1])

def extrema_1d(p0,p1,p2,p3):
    # derivative roots for cubic bezier
    a = -p0 + 3*p1 - 3*p2 + p3
    b = 2*(p0 - 2*p1 + p2)
    c = p1 - p0
    roots=[]
    if abs(a) < 1e-12:
        if abs(b) > 1e-12:
            t=-c/b
            if 0<t<1: roots.append(t)
    else:
        disc=b*b-4*a*c
        if disc >= 0:
            sd=math.sqrt(disc)
            for t in ((-b+sd)/(2*a),(-b-sd)/(2*a)):
                if 0<t<1: roots.append(t)
    return roots

def path_bounds(start, segments):
    xs=[start[0]]; ys=[start[1]]
    for typ,p0,p1,p2,p3 in segments:
        xs += [p3[0]]; ys += [p3[1]]
        if typ=='C':
            ts=set(extrema_1d(p0[0],p1[0],p2[0],p3[0]) + extrema_1d(p0[1],p1[1],p2[1],p3[1]))
            for t in ts:
                p=cubic_point(p0,p1,p2,p3,t); xs.append(p[0]); ys.append(p[1])
    return min(xs),min(ys),max(xs),max(ys)

def lottie_shape(start, segments, scale, ox, oy):
    # vertices are start points of segments, with incoming/outgoing tangents.
    verts=[]; ins=[]; outs=[]
    current=start
    for idx,(typ,p0,p1,p2,p3) in enumerate(segments):
        assert abs(p0[0]-current[0])<1e-6 and abs(p0[1]-current[1])<1e-6
        # Add vertex p0. Incoming is from previous segment, resolved below.
        verts.append(p0)
        if typ=='C': out=(p1[0]-p0[0], p1[1]-p0[1])
        else: out=(0.0,0.0)
        outs.append(out)
        ins.append((0.0,0.0))
        current=p3
    # Set incoming tangent for each destination vertex. For closing final segment, destination is vertex 0.
    for j,(typ,p0,p1,p2,p3) in enumerate(segments):
        dest=(j+1) % len(verts)
        if typ=='C': inn=(p2[0]-p3[0], p2[1]-p3[1])
        else: inn=(0.0,0.0)
        ins[dest]=inn
    def tr(p): return [round(p[0]*scale+ox,4), round(p[1]*scale+oy,4)]
    def tv(v): return [round(v[0]*scale,4), round(v[1]*scale,4)]
    return {'i':[tv(x) for x in ins], 'o':[tv(x) for x in outs], 'v':[tr(x) for x in verts], 'c':True}

def kf_scalar(t0, s0, t1, s1):
    return {'a':1,'k':[
        {'t':t0,'s':[s0],'e':[s1],'i':{'x':[0.667],'y':[1.0]},'o':{'x':[0.333],'y':[0.0]}},
        {'t':t1,'s':[s1]}
    ]}

def hold_then_ramp(t_hold, start, t_end, end):
    return {'a':1,'k':[
        {'t':0,'s':[start],'h':1},
        {'t':t_hold,'s':[start],'e':[end],'i':{'x':[0.667],'y':[1.0]},'o':{'x':[0.333],'y':[0.0]}},
        {'t':t_end,'s':[end]}
    ]}

def ramp_then_hold(t0,start,t1,end):
    return {'a':1,'k':[
        {'t':t0,'s':[start],'e':[end],'i':{'x':[0.667],'y':[1.0]},'o':{'x':[0.333],'y':[0.0]}},
        {'t':t1,'s':[end],'h':1},
        {'t':OP,'s':[end]}
    ]}

def make_group(name, shape, rgb, fill=False, stroke=False):
    items=[{'ty':'sh','ks':{'a':0,'k':shape},'nm':'Logo Path','mn':'ADBE Vector Shape - Group','hd':False}]
    if fill:
        items.append({'ty':'fl','c':{'a':0,'k':rgb},'o':{'a':0,'k':100},'r':1,'bm':0,'nm':'Fill','mn':'ADBE Vector Graphic - Fill','hd':False})
        op = hold_then_ramp(TRACE_END,0,FILL_END,100)
    if stroke:
        items.append({'ty':'st','c':{'a':0,'k':rgb},'o':{'a':0,'k':100},'w':{'a':0,'k':STROKE_WIDTH_CANVAS},'lc':1,'lj':1,'ml':4,'bm':0,'nm':'Stroke','mn':'ADBE Vector Graphic - Stroke','hd':False})
        items.append({'ty':'tm','s':{'a':0,'k':0},'e':kf_scalar(0,0,TRACE_END,100),'o':{'a':0,'k':0},'m':1,'ix':1,'nm':'Trim Paths 1','mn':'ADBE Vector Filter - Trim','hd':False})
        op = ramp_then_hold(TRACE_END,100,FILL_END,0)
    items.append({'ty':'tr','p':{'a':0,'k':[0,0]},'a':{'a':0,'k':[0,0]},'s':{'a':0,'k':[100,100]},'r':{'a':0,'k':0},'o':op,'sk':{'a':0,'k':0},'sa':{'a':0,'k':0},'nm':'Transform'})
    return {'ty':'gr','it':items,'nm':name,'np':len(items),'cix':2,'bm':0,'ix':1,'mn':'ADBE Vector Group','hd':False}

def build(rgb):
    xml=ET.parse(SRC).getroot()
    ns={'svg':'http://www.w3.org/2000/svg'}
    paths=xml.findall('.//svg:path',ns)
    if len(paths)!=1: raise ValueError(f'Expected exactly one path, found {len(paths)}')
    d=paths[0].attrib['d']
    start,segs=parse_svg_path(d)
    bx0,by0,bx1,by1=path_bounds(start,segs)
    bw,bh=bx1-bx0,by1-by0
    scale=min((W-2*MARGIN)/bw,(H-2*MARGIN)/bh)
    ox=(W-bw*scale)/2 - bx0*scale
    oy=(H-bh*scale)/2 - by0*scale
    shape=lottie_shape(start,segs,scale,ox,oy)
    layer={
        'ddd':0,'ind':1,'ty':4,'nm':'Medix Logo','sr':1,
        'ks':{'o':{'a':0,'k':100},'r':{'a':0,'k':0},'p':{'a':0,'k':[W/2,H/2,0]},'a':{'a':0,'k':[W/2,H/2,0]},'s':{'a':0,'k':[100,100,100]}},
        'ao':0,
        'shapes':[make_group('Final Fill',shape,rgb,fill=True), make_group('Drawing Stroke',shape,rgb,stroke=True)],
        'ip':IP,'op':OP,'st':0,'bm':0
    }
    anim={'v':VERSION,'fr':FR,'ip':IP,'op':OP,'w':W,'h':H,'nm':'Medix Logo Draw','ddd':0,'assets':[],'layers':[layer],'markers':[]}
    return anim, (bx0,by0,bx1,by1), scale

def write(name,rgb):
    anim,bounds,scale=build(rgb)
    path=OUTDIR/name
    path.write_text(json.dumps(anim,separators=(',',':'),ensure_ascii=False),encoding='utf-8')
    return path,bounds,scale

if __name__=='__main__':
    for name,rgb in [('logo_white.json',[1,1,1,1]),('logo_blue.json',[33/255,98/255,251/255,1])]:
        p,b,s=write(name,rgb)
        print(f'{p.name}: {p.stat().st_size} bytes; source bounds={b}; scale={s:.8f}')
