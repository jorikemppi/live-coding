pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-- Live coding session from March 24, 2020.
-- Code provided in the state it was at the end of the broadcast.
-- Show available on YouTube - https://www.youtube.com/watch?v=26IUeh9XDEY

--2D ROTATION MATRIX
--
--R(Θ) = | cos(Θ)  -sin(Θ) |
--       | sin(Θ)  cos(Θ)  |
--
--x' = x * cos(Θ) - y * sin(Θ)
--y' = x * sin(Θ) + y * cos(Θ)

function create_star(distance)

 star={}
 
 theta=rnd(1)
 
 star.direction_x=cos(theta)
 star.direction_y=sin(theta)
 star.distance=distance
 star.speed=0.3+rnd(0.3)

 return star 
 
end

function draw_star(star)

 screen_distance=1.1^star.distance
 
 pset(screen_distance*star.direction_x, screen_distance*star.direction_y, 7)
 
end

function draw_plasma()

 for x=0,15 do
  
  plasma_func1=3*cos(x*0.05+f*0.01)
  
  for y=0,7 do
  
   value=4
   
   value+=4*sin(f*0.01 + x*(0.1*cos(y*0.03+f*0.008)))
   
   value+=plasma_func1
   
   value=mid(0,7,flr(value))
   
   spr(value, x*8, 32+y*8)
  
  end
  
 end

end

function draw_twister()

 camera(0,-64)
 
 for i=0,3 do
 
  for x=0,127 do
  
   color(8*16+2)
   if i==0 or i==2 then
    color(9*16+4)
   end
   
   phase=0.01*f+i*0.25+0.3*sin(f*0.008+x*0.001)
   
   twister_size=32
   y1=twister_size*sin(phase)
   y2=twister_size*sin((phase+0.25))
   
   if y1<y2 then
    brightness=mid(1,17,flr(y2-y1-7))
	fillp(dither[brightness])
    line(x,y1,x,y2)
   end
  
  end
 
 end
 
 fillp()
 
 camera()
 
end


function draw_twister_textured()

 camera(0,-64)
 

 
 for i=0,3 do
 
  pal()
  palt(0, false)
  
  if i==0 or i==2 then
   pal(8, 9)
   pal(2, 4)
  end
 
  for x=0,127 do
  
   phase=0.01*f+i*0.25+0.3*sin(f*0.008+x*0.001)
   
   twister_size=32
   y1=twister_size*sin(phase)
   y2=twister_size*sin((phase+0.25))
   
   if y1<y2 then
    sspr(x, 32, 1, 64, x, y1, 1, y2-y1)
   end
  
  end
 
 end
 
 fillp()
 
 camera()
 
end


		
function round(n)
 return flr(n+0.5)
end

function flatten_point(x, y, z)
 return round(-64*(x/z)+64), round(-64*(y/z)+64)
end

--3D ROTATION BASIC MATRICES
--
--        | 1    0        0    |      x' = x
--Rx(Θ) = | 0  cos(Θ)  -sin(Θ) |      y' = y * cos(Θ) - z * sin(Θ)
--        | 0  sin(Θ)   cos(Θ) |      z' = y * sin(Θ) + z * cos(Θ)
--
--        |  cos(Θ)  0  sin(Θ) |      x' = x * cos(Θ) + z * sin(Θ)
--Ry(Θ) = |    0     1     0   |      y' = y
--        | -sin(Θ)  0  cos(Θ) |      z' = -x * sin(Θ) + z * cos(Θ)
--
--        | cos(Θ)  -sin(Θ)  0 |      x' = x * cos(Θ) - y * sin(Θ)
--Rz(Θ) = | sin(Θ)   cos(Θ)  0 |      y' = x * sin(Θ) + y * cos(Θ)
--        |    0        0    1 |      z' = z

function draw_cube(x, y, z)

 z-=8.5
 
 cube_vertices={
  {-1,-1,-1},{1,-1,-1},{1,1,-1},{-1,1,-1},
  {-1,-1,1},{1,-1,1},{1,1,1},{-1,1,1}
 }
 
--        |  cos(Θ)  0  sin(Θ) |      x' = x * cos(Θ) + z * sin(Θ)
--Ry(Θ) = |    0     1     0   |      y' = y
--        | -sin(Θ)  0  cos(Θ) |      z' = -x * sin(Θ) + z * cos(Θ)

 theta=0.005*f
 
 for i=1,#cube_vertices do
 
  vertex=cube_vertices[i]
  
  xrot = vertex[1]*cos(theta) + vertex[3]*sin(theta)
  yrot = vertex[2]
  zrot = -vertex[1]*sin(theta) + vertex[3]*cos(theta)
  
  cube_vertices[i]={xrot, yrot, zrot}
  
 end
 
 
 --        | 1    0        0    |      x' = x
--Rx(Θ) = | 0  cos(Θ)  -sin(Θ) |      y' = y * cos(Θ) - z * sin(Θ)
--        | 0  sin(Θ)   cos(Θ) |      z' = y * sin(Θ) + z * cos(Θ)

 theta=0.008*f
 
 for i=1,#cube_vertices do
 
  vertex=cube_vertices[i]
  
  xrot = vertex[1]
  yrot = vertex[2] * cos(theta) - vertex[3]*sin(theta)
  zrot = vertex[2] * sin(theta) + vertex[3]*cos(theta)
  
  cube_vertices[i]={xrot, yrot, zrot}
  
 end
 
 
 for i=1,#cube_vertices do
  
  cube_vertices[i][1]+=x
  cube_vertices[i][2]+=y
  cube_vertices[i][3]+=z
 
 end

 for cube_line in all(cube_lines) do
 
  x1, y1 = flatten_point( cube_vertices[cube_line[1]][1], cube_vertices[cube_line[1]][2], cube_vertices[cube_line[1]][3])
  x2, y2 = flatten_point( cube_vertices[cube_line[2]][1], cube_vertices[cube_line[2]][2], cube_vertices[cube_line[2]][3])
  
  line(x1,y1,x2,y2,7)
  
 end
end
 
function _init()

 dither={0b0000000000000000,
         0b1000000000000000,
		 0b1000000000100000,
		 0b1000000010100000,
		 0b1010000010100000,
		 0b1010010010100000,
		 0b1010010010100001,
		 0b1010010010100101,
		 0b1010010110100101,
		 0b1010011110100101,
		 0b1010011110100111,
		 0b1010011110101111,
		 0b1010111110101111,
		 0b1110111110101111,
		 0b1110111110111111,
		 0b1110111111111111,
		 0b1111111111111111}
 
 cube_lines={
  {1,2},{2,3},{3,4},{4,1},
  {5,6},{6,7},{7,8},{8,5},
  {1,5},{2,6},{3,7},{4,8}
 }

 stars_amount=100 
 starfield={}
 
 for i=1,stars_amount do  
  add(starfield, create_star(rnd(50)))  
 end
 
 f=0
  
end

function _update60()

 f+=1
 
end

function _draw()

 cubex_start=0
 cubey_start=0
 cubez_start=6
 
 theta=0.008*f
 
 --        | 1    0        0    |      x' = x
--Rx(Θ) = | 0  cos(Θ)  -sin(Θ) |      y' = y * cos(Θ) - z * sin(Θ)
--        | 0  sin(Θ)   cos(Θ) |      z' = y * sin(Θ) + z * cos(Θ)

 cubex=cubex_start
 cubey=cubey_start*cos(theta) - cubez_start*sin(theta)
 cubez=cubey_start*sin(theta) + cubez_start*cos(theta)

 cls()
 
  draw_plasma()
 memcpy(0x0800, 0x6800, 4096)
 
 cls()
 
  for i=1,stars_amount do
 
  if starfield[i].distance>80 then
   starfield[i]=create_star(7)
  end
  
 end
 
 camera(-64, -64)
 for star in all(starfield) do
  star.distance+=star.speed
  draw_star(star)
 end
 
 camera()
 
 if cubez<0 then draw_cube(cubex, cubey, cubez) end
 
 draw_twister_textured()
 
 if cubez>=0 then draw_cube(cubex, cubey, cubez) end
 
 --memcpy(0x6000, 0, 8192)
 
 --print(stat(1), 0, 0)
 
 for i=1,100 do
  
  memcpy(0x6000+rnd(0x2000-16),0x6000+rnd(0x2000-16),4)
  
 end
 
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000220000028820002888820088888800000000000000000000000000000000000000000000000000000000000000000
00000000000000000002200000288200002882000288882008888880088888800000000000000000000000000000000000000000000000000000000000000000
00000000000220000028820000888800028888200888888008888880088888800000000000000000000000000000000000000000000000000000000000000000
00000000000220000028820000888800028888200888888008888880088888800000000000000000000000000000000000000000000000000000000000000000
00000000000000000002200000288200002882000288882008888880088888800000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000220000028820002888820088888800000000000000000000000000000000000000000000000000000000000000000
