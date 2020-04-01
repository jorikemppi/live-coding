pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-- Live coding session from March 24, 2020.
-- Code provided in the state it was at the end of the broadcast.
-- Show available on YouTube - https://youtu.be/tZy-53_7Fd0

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

--2D ROTATION MATRIX
--
--R(Θ) = | cos(Θ)  -sin(Θ) |
--       | sin(Θ)  cos(Θ)  |
--
--x' = x * cos(Θ) - y * sin(Θ)
--y' = x * sin(Θ) + y * cos(Θ)

function flatten_point(x,y,z)
 return {round(-64*(x/z)+64),round(-64*(y/z)+64)}
end

function round(t)
 return flr(t+0.5)
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


--STEPS
--
--1. Define 3D object in space
--2. Transform in world space
--3. Transform to camera space
--4. Flatten front facing triangles to 2D space and send them to render queue
--5. Sort render queue by depth (use highest Z)
--6. Draw triangles

function draw_cube()

 base_tri_vertices={
  {-1,-1,-1},{1,-1,-1},{1,1,-1},{-1,1,-1},  --negative z = away from camera
  {-1,-1,1},{1,-1,1},{1,1,1},{-1,1,1}
 }
 
 base_tris={
  {4,3,1},{3,2,1},
  {5,6,7},{7,8,5},
  {1,5,8},{8,4,1},
  {2,3,7},{7,6,2},
  {6,5,1},{1,2,6},
  {8,7,3},{3,4,8}
 }
 
 base_mats={0,1,0,1,0,1,0,1,0,1,0,1}
 
 theta=f*0.01
 for i=1,#base_tri_vertices do
  newx=base_tri_vertices[i][1]*cos(theta)+base_tri_vertices[i][3]*sin(theta)
  newy=base_tri_vertices[i][2]
  newz=-base_tri_vertices[i][1]*sin(theta)+base_tri_vertices[i][3]*cos(theta)
  base_tri_vertices[i]={newx,newy,newz}
 end
 
 --        | 1    0        0    |      x' = x
--Rx(Θ) = | 0  cos(Θ)  -sin(Θ) |      y' = y * cos(Θ) - z * sin(Θ)
--        | 0  sin(Θ)   cos(Θ) |      z' = y * sin(Θ) + z * cos(Θ)
--

  theta=f*0.012
 for i=1,#base_tri_vertices do
  newx=base_tri_vertices[i][1]
  newy=base_tri_vertices[i][2]*cos(theta)-base_tri_vertices[i][3]*sin(theta)
  newz=base_tri_vertices[i][2]*sin(theta)+base_tri_vertices[i][3]*cos(theta)
  base_tri_vertices[i]={newx,newy,newz}
 end
 
 --camera translation
 for vert in all(base_tri_vertices) do
  vert[3]-=4
 end

 for k,tri in pairs(base_tris) do
 
  v={}
  
  depth=0
  
  --CALCULATE NORMAL

--1. Get vectors a = vertex2-vertex1 and b = vertex3-vertex1
--2. Calculate the cross product s of these vectors
--    s1 = a2b3 - a3b2
--    s2 = a3b1 - a1b3
--    s3 = a1b2 - a2b1
--3. Turn the cross product into a unit vector
--    length = square root of the sum of the squares of all the components
--	 then divide each component by the length of the vector
--4. That's your normal!

  for i=1,3 do
   add(v, base_tri_vertices[tri[i]])
   --v[i][3]-=8
   depth-=v[i][3]
  end
  
  vec_a={
   v[2][1]-v[1][1],
   v[2][2]-v[1][2],
   v[2][3]-v[1][3]
  }
  
  vec_b={
   v[3][1]-v[1][1],
   v[3][2]-v[1][2],
   v[3][3]-v[1][3]
  }
  --2. Calculate the cross product s of these vectors
--    s1 = a2b3 - a3b2
--    s2 = a3b1 - a1b3
--    s3 = a1b2 - a2b1
  cross_product={
   vec_a[2]*vec_b[3] - vec_a[3]*vec_b[2],
   vec_a[3]*vec_b[1] - vec_a[1]*vec_b[3],
   vec_a[1]*vec_b[2] - vec_a[2]*vec_b[1]}
  
  len = sqrt(cross_product[1]^2 + cross_product[2]^2 + cross_product[3]^2)
  
  cross_product[3]/=len
  
  v_flat={}
  
  for i=1,3 do
   add(v_flat, flatten_point(v[i][1],v[i][2],v[i][3]))
  end
  
  --line(v_flat[1][1],v_flat[1][2],v_flat[2][1],v_flat[2][2],7)  
  --line(v_flat[2][1],v_flat[2][2],v_flat[3][1],v_flat[3][2],7)  
  --line(v_flat[3][1],v_flat[3][2],v_flat[1][1],v_flat[1][2],7)
  
  --color(base_mats[k])
  
  --trifill({
  --         {v_flat[1][1],v_flat[1][2]},
  --         {v_flat[2][1],v_flat[2][2]},
  --         {v_flat[3][1],v_flat[3][2]}
  --	  })
  
  new_rq_tri={}
  add(new_rq_tri, {v_flat[1][1],v_flat[1][2]})
  add(new_rq_tri, {v_flat[2][1],v_flat[2][2]})
  add(new_rq_tri, {v_flat[3][1],v_flat[3][2]})
  add(new_rq_tri, depth)
  add(new_rq_tri, base_mats[k])
  add(new_rq_tri, cross_product[3])
  
  add(rq, new_rq_tri)
  
 end
 
 render_queue() 

end

function render_queue()

 for i=1,#rq do
  j=i
  while j>1 and rq[j-1][4] < rq[j][4] do
   rq[j],rq[j-1] = rq[j-1],rq[j]
   j-=1
  end 
 end

 for i=1,#rq do
 
  --color(rq[i][5])
  
  --color(0)
  --if rq[i][6]>0 then
   --color(7)
  --end
  
  brightness=mid(0,3,flr(4*rq[i][6]))
  
  color(sget(3-brightness,rq[i][5]))
  
  trifill({
           {rq[i][1][1],rq[i][1][2]},
           {rq[i][2][1],rq[i][2][2]},
           {rq[i][3][1],rq[i][3][2]}})
  
 end

end

function _init()

 --ORDERED DITHERING PATTERNS
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
 


 f=0
 
end

function _update60()

 f+=1
 
end

function _draw()

 rq={}

 cls()
 
 draw_cube()
 
 --trifill({{80,50},{20,20},{70,100}})
 
end

--INSERTION SORT
--
--1. Declare that i is 1
--2. Declare that j is i
--3. While j > 1 and A[j-1] > A[j]
--   a. swap A[j-1] and [j]
--   b. decrement j by 1
--4. Increment i by 1
--5. Repeat 2-4 until entire list has been iterated
--
--TRIANGLE RASTERIZATION
--
--1. Sort the vertices by y
--2. x4 = the point on v3-v1 where y is equal to y2
--     x4 = x1 + ((y2 - y1) / (y3 - y1)) * (x3 - x1)
--3. Split the triangle into two flat based triangles
--        top triangle = x1, y1, x2, y2, x4, y2
--	 bottom triangle = x3, y3, x2, y2, x4, y2
--4. Draw both triangles
--     a. define a function (xa, ya, xb, yb, xc, direction)
--     b. define two x variables and a y variable at the tip of the triangle
--	 c. calculate slopes for both sides of the triangle
--	       slope1 = (xb-xa)/(yb-ya)
--	       slope2 = (xc-xa)/(yb-ya)
--     d. draw each scanline and increment the x variables each time
--	       scanx1 += direction * slope1
--		   scanx2 += direction * slope2
		   
function trifill(tri2d)

 for i=1,3 do
  j=i
  while j>1 and tri2d[j-1][2] > tri2d[j][2] do
   tri2d[j],tri2d[j-1] = tri2d[j-1],tri2d[j]
   j-=1
  end 
 end
 
 add(tri2d, {tri2d[1][1] + ((tri2d[2][2] - tri2d[1][2]) / (tri2d[3][2] - tri2d[1][2])) * (tri2d[3][1] - tri2d[1][1]), tri2d[2][2]})

 flat_trifill(tri2d[1][1], tri2d[1][2], tri2d[2][1], tri2d[2][2], tri2d[4][1], 1)
 flat_trifill(tri2d[3][1], tri2d[3][2], tri2d[2][1], tri2d[2][2], tri2d[4][1], -1)
 
end

function flat_trifill(xa, ya, xb, yb, xc, direction)

 scanx1,scanx2=xa,xa
 
 slope1 = (xb-xa)/(yb-ya)
 slope2 = (xc-xa)/(yb-ya)
 
 for scany=ya,yb,direction do
  line(scanx1,scany,scanx2,scany)
  scanx1+=direction*slope1
  scanx2+=direction*slope2
 end

end

__gfx__
82100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
94200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
