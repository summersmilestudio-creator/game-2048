from PIL import Image, ImageDraw, ImageFont, ImageFilter
S=1024
img=Image.new("RGB",(S,S))
px=img.load()
# diagonal gradient background: deep indigo -> teal
c1=(34,40,86); c2=(20,90,110)
for y in range(S):
    for x in range(0,S):
        t=(x+y)/(2*S)
        px[x,y]=(int(c1[0]+(c2[0]-c1[0])*t),int(c1[1]+(c2[1]-c1[1])*t),int(c1[2]+(c2[2]-c1[2])*t))
d=ImageDraw.Draw(img,"RGBA")
def font(sz):
    for f in ["C:/Windows/Fonts/segoeuib.ttf","C:/Windows/Fonts/arialbd.ttf","arialbd.ttf"]:
        try: return ImageFont.truetype(f,sz)
        except: pass
    return ImageFont.load_default()
def tile(cx,cy,sz,color,num,fsz):
    r=sz//2; rad=int(sz*0.22)
    # soft shadow
    sh=Image.new("RGBA",(S,S),(0,0,0,0)); sd=ImageDraw.Draw(sh)
    sd.rounded_rectangle([cx-r,cy-r+14,cx+r,cy+r+14],rad,fill=(0,0,0,90))
    sh=sh.filter(ImageFilter.GaussianBlur(18)); img.paste(sh,(0,0),sh)
    d.rounded_rectangle([cx-r,cy-r,cx+r,cy+r],rad,fill=color)
    # subtle top highlight
    d.rounded_rectangle([cx-r,cy-r,cx+r,cy-r+int(sz*0.30)],rad,fill=(255,255,255,38))
    f=font(fsz); tb=d.textbbox((0,0),num,font=f)
    d.text((cx-(tb[2]-tb[0])/2,cy-(tb[3]-tb[1])/2-tb[1]),num,font=f,fill=(255,255,255))
# 2x2 ascending tiles, centered cluster with margin
gap=46; sz=330
cluster=2*sz+gap; left=(S-cluster)//2; top=(S-cluster)//2
tiles=[("2",(236,228,214),(120,110,96)),("4",(247,178,102),None),("8",(242,124,86),None),("16",(245,196,72),None)]
pos=[(left,top),(left+sz+gap,top),(left,top+sz+gap),(left+sz+gap,top+sz+gap)]
fontcols=[(120,110,96),(255,255,255),(255,255,255),(255,255,255)]
for (num,col,_),(x,y),fc in zip(tiles,pos,fontcols):
    cx,cy=x+sz//2,y+sz//2; r=sz//2; rad=int(sz*0.22)
    sh=Image.new("RGBA",(S,S),(0,0,0,0)); sd=ImageDraw.Draw(sh)
    sd.rounded_rectangle([cx-r,cy-r+14,cx+r,cy+r+14],rad,fill=(0,0,0,80)); sh=sh.filter(ImageFilter.GaussianBlur(16)); img.paste(sh,(0,0),sh)
    d.rounded_rectangle([cx-r,cy-r,cx+r,cy+r],rad,fill=col)
    d.rounded_rectangle([cx-r,cy-r,cx+r,cy-r+int(sz*0.30)],rad,fill=(255,255,255,40))
    fsz=190 if len(num)<2 else 150
    f=font(fsz); tb=d.textbbox((0,0),num,font=f)
    d.text((cx-(tb[2]-tb[0])/2,cy-(tb[3]-tb[1])/2-tb[1]),num,font=f,fill=fc)
img.save("assets/app_icon.png")
print("icon saved")
