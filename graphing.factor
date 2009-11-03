! Copyright (C) 2009 Your name.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel sequences math math.rectangles
accessors combinators colors opengl
ui ui.gadgets ui.gadgets.editors ui.gestures ui.render ;
IN: graphing

! test

TUPLE: box-gadget < gadget 
 { box rect }
;

: box-gadget-down ( gadget -- )
 dup hand-rel swap [ swap >>loc ] change-box drop
;

: box-gadget-drag ( gadget -- )
 dup [ hand-rel ] keep box>> loc>> 
 [ - ] 2map
 swap [ swap >>dim ] change-box drop
;

: box-gadget-up ( gadget -- )
 { 0 0 } swap [ swap >>dim ] change-box drop
;


M: box-gadget handle-gesture
{
 { [ over button-down? ]
   [ dup box-gadget-down relayout-1 drop f ] }
 { [ over button-up? ]
   [ dup box-gadget-up relayout-1 drop f ] }
 { [ over drag? ] 
   [ dup box-gadget-drag relayout-1 drop f ] }
 [ 2drop t ] 
} cond
;

M: box-gadget draw-gadget*
255 0 0 100 <rgba> gl-color
box>> [ loc>> ] keep dim>>
gl-fill-rect
;

