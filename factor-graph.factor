! Copyright (C) 2009 Michael Worcester
! See http://factorcode.org/license.txt for BSD license.
USING: 
kernel arrays inspector fry
accessors sorting sequences combinators sequences.deep
math math.constants math.order math.ranges 
math.functions math.rectangles math.vectors
ui ui.gadgets ui.gadgets.editors ui.gestures ui.render
colors opengl opengl.gl opengl.glu
specialized-arrays.instances.float
;

IN: graphing

! test

! NOTE: range is { min size }, NOT { min max }

TUPLE: graph-gadget < gadget 
 x-series y-series x-range y-range auto-range
 { box rect }
;

: box-fill-color ( -- color ) 255 0 0 0.2 <rgba> ;
: box-line-color ( -- color ) 0 0 0 1 <rgba> ;
: line-color ( -- color ) 255 0 0 255 <rgba> ;

: graph-gadget-down ( gadget -- )
 [ box>> ] [ hand-rel ] bi >>loc drop
;

: graph-gadget-drag ( gadget -- )
 [ box>> ] [ [ hand-rel ] [ box>> loc>> ] bi v- ] bi >>dim drop
;

: norm-range ( val range -- norm )
 [ last * ] [ first ] bi + >float
;

: hand>2 ( i loc dim -- val )
 [ drop - ] keep /
;

: >x-params ( gadget -- start end range x w )
 {
     [ x-range>> ]
     [ box>> loc>> first ]
     [ box>> dim>> first ]
     [ loc>> first ]
     [ [ loc>> first ] [ dim>> first ] bi + ]
 } cleave
;

! Alas, stupid y being upside down (plot versus pixels) means
! we have this... monstrosity (even if it is quite cleave'r).
: >y-params ( gadget -- start end range y h )
 {
     [ y-range>> ]
     ! this does graph.height - (box.y + box.height)
     [ [ dim>> last ] [ [ box>> dim>> last ] [ box>> loc>> last ] bi + ] bi - ]
     [ box>> dim>> last ]
     [ loc>> last ]
     [ [ loc>> last ] [ dim>> last ] bi + ]
 } cleave
;

! BAD: still uses a rot here...
: mangle-range ( range a b -- range )
 swap rot [ [ last * ] curry bi@ ] [ first + ] bi swap 2array
;

: box>range ( start end range y h  -- range )
 [ hand>2 ] 2curry bi@ mangle-range
;

: box-positive? ( gadget -- ? )
 box>> dim>> first 0 >
;

: reset-box ( gadget -- box )
 box>> { 0 0 } >>dim
;

: graph-gadget-up ( gadget -- )
 dup box-positive?
 [
   f >>auto-range
   dup 
   [ >y-params box>range >>y-range ]
   [ >x-params box>range >>x-range ] bi
 ]
 [
   t >>auto-range
 ] if

 reset-box drop
;

: complete-gesture ( gesture gadget -- ? )
 relayout-1 drop f
;

M: graph-gadget handle-gesture
{
 { [ over button-down? ]
   [ dup graph-gadget-down complete-gesture ] }
 { [ over button-up? ]
   [ dup graph-gadget-up complete-gesture ] }
 { [ over drag? ] 
   [ dup graph-gadget-drag complete-gesture ] }
 [ 2drop t ] 
} cond
;

: gen-sin-ranges ( -- xx yy )
 0 2pi 0.01 <range> dup [ sin ] map
;

: find-range ( sequence -- range )
 natural-sort [ first ] [ last ] bi over - 2array
;

: normalize-series ( range series -- normalized-series )
 swap first2 '[ _ - _ / ] map
;

: <graph-gadget> ( xx yy -- graph-gadget )
 graph-gadget new
 { 0 1 } >>x-range
 { 0 1 } >>y-range
 t >>auto-range
 swap >>y-series
 swap >>x-series
;


: auto-range-find ( gadget -- )
 dup auto-range>>
  [
    dup x-series>> find-range >>x-range
    dup y-series>> find-range >>y-range
  ] when
 drop
;

: draw-box? ( box -- ? )
 dim>> first 0 >
;

: draw-box ( gadget -- )
 box>> dup draw-box?
 [
   [ loc>> ] [ dim>> ] bi
   [ box-fill-color gl-color gl-fill-rect ]
   [ box-line-color gl-color gl-rect ] 2bi
 ] [ drop ] if 
;

: x>screen ( gadget -- x-screen )
 [ x-range>> ] [ x-series>> ] bi normalize-series
 ! [ dim>> first ] bi
 ! [ * ] curry map
;

: y>screen ( gadget -- y-screen )
 [ y-range>> ] [ y-series>> ] bi normalize-series
 '[ 1 swap - ] map
! [ dim>> last ] bi
;

: length-and-series ( gadget -- length x-screen y-screen )
 [ x-series>> length ] [ x>screen ] [ y>screen ] tri
;

: series>array ( x-screen y-screen -- xy-screen-array )
 [ 2array ] { } 2map-as flatten >float-array
;

: draw-line-strip ( length -- )
 GL_LINE_STRIP 0 rot glDrawArrays
;

: draw-series ( gadget -- )
 length-and-series series>array gl-vertex-pointer
 line-color gl-color
 draw-line-strip
;

: norm-dim ( val -- -1/w 1/w )
 1 swap / dup 0 swap - swap
;

: norm-height ( gadget -- -1/h 1/h )
 dim>> last
 1 swap / dup 0 swap - swap
;


M: graph-gadget draw-gadget*

 ! this is a bit nasty again, I'll clean it up later.
 GL_LINE_SMOOTH glEnable
 [
  [ [ [ dim>> first norm-dim ] [ dim>> last norm-dim ] bi gluOrtho2D ] keep
    [ auto-range-find ] [ draw-series ] bi ] do-matrix ]
 [ draw-box ] bi
;

