! Copyright (C) 2009 Your name.
! See http://factorcode.org/license.txt for BSD license.
USING: 
kernel arrays inspector 
accessors sorting sequences combinators sequences.deep
math math.constants math.order math.ranges 
math.functions math.rectangles
ui ui.gadgets ui.gadgets.editors ui.gestures ui.render
colors opengl opengl.gl
specialized-arrays.instances.float
;

IN: graphing

! test

! NOTE: range is { min size }, NOT { min max }

TUPLE: graph-gadget < gadget 
 x-series y-series x-range y-range auto-range
 { box rect }
;

: graph-gadget-down ( gadget -- )
 dup hand-rel swap [ swap >>loc ] change-box drop
;

: graph-gadget-drag ( gadget -- )
 dup [ hand-rel ] keep box>> loc>> 
 [ - ] 2map
 swap [ swap >>dim ] change-box drop
;

: hand>x ( gadget hand-x -- x )
 over loc>> first - over dim>> first /
 swap x-range>> [ last * ] keep first + >float
;

: hand>y ( gadget hand-y -- y )
 over loc>> last - over dim>> last / 1 swap -
 swap y-range>> [ last * ] keep first + >float
;

: box>start-x ( gadget box -- start-x ) loc>> first hand>x ;
: box>end-x ( gadget box -- end-x )
 [ loc>> first ] keep dim>> first + hand>x
;

: box>start-y ( gadget box -- start-y ) loc>> last hand>y ;
: box>end-y ( gadget box -- end-y )
 [ loc>> last ] keep dim>> last + hand>y
;

: graph-gadget-up ( gadget -- )
 dup box>>
 dim>> first 0 >
 [ 
   dup box>>
   [ box>start-x ] 2keep
   [ box>end-x ] 2keep
   [ box>end-y ] 2keep
   [ box>start-y ] 2keep
   drop
   -rot over - 2array >>y-range
   -rot over - 2array >>x-range
   f >>auto-range
 ]
 [
   t >>auto-range
 ] if

 { 0 0 } swap [ swap >>dim ] change-box
 drop
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
 0 2pi 0.01 <range>
 [ ] map dup [ sin ] map
;

: find-range ( sequence -- range )
 [ <=> ] sort [ first ] keep last over - 2array
;

: find-xy-ranges ( xx yy -- y-range yy x-range xx )
 [ find-range ] keep rot [ find-range ] keep
;

: normalize-series ( range series -- normalized-series )
 [ over first - over second / ] map nip
;

: <graph-gadget> ( xx yy -- graph-gadget )
 graph-gadget new
 { 0 1 } >>x-range
 { 0 1 } >>y-range
 t >>auto-range
 swap >>y-series
 swap >>x-series
;

M: graph-gadget draw-gadget*
 dup auto-range>>
  [ dup x-series>> find-range >>x-range ] [ ] if
 dup auto-range>>
  [ dup y-series>> find-range >>y-range ] [ ] if

 [ x-range>> ] keep [ x-series>> ] keep -rot
 normalize-series
 over dim>> first swap
 [ over * ] map nip
 over
 [ y-range>> ] keep [ y-series>> ] keep -rot
 normalize-series
 over dim>> last swap
 [ 1 swap - over * ] map nip
 rot swap
 [ 2array ] { } 2map-as flatten >float-array
 gl-vertex-pointer
 255 0 0 255 <rgba> gl-color
 x-series>> length GL_LINE_STRIP 0 rot glDrawArrays


 box>> [ loc>> ] keep dim>>
 dup first 0 >
 [
   255 0 0 0.2 <rgba> gl-color
   [ gl-fill-rect ] 2keep
   0 0 0 1 <rgba> gl-color
   gl-rect
 ] [ 2drop ] if
;
