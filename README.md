# Pitches and Rhythm Transformer *Plugin for MuseScore 4.x*

A MuseScore 4.x plugin that performs the rotation, retrograde, and inversion transformations to pitches without altering rhythm, rhythm withou altering pitches, or transfor both pitches and rhythm. Supports multiple voices and staff selections.

## Features
 - Tuplets are handeled correctly no matter the internal subdivision and number of notes inside the tuplet. 
 - In the case of transposed instruments, transformations applied in one pitch mode (concert or score pitch) are correctly mirrored in the other mode. 
 - Pivot notes are read and determined according to the active concert/score pitch mode. 


## Usage
 - Rotation: Choose the number of steps by which to rotate pitches, rhythm, or both. A positive number for forward rotation, negative for backwards.
 - Retrograde: Choose to reverse pitches, rhythm, or both. 
 - Inversion: Select the type of inversion (diatonic or chromatic) and choose to invert by a specific pitch or by outermost pitches.
 - **Caution:** A diatonic inversion applied to non-diatonic notes disregards accidentals. ex: key of C Maj, Both Db and D# are treated as D natural. This is not a bug but is due to a concious choice of implementation. 

 ## Demo
 *Rotation:*   
 
 ![move](https://github.com/Ash-86/Move-Selection/assets/108089527/4822e543-07fb-4eef-819d-17feae32a988)

 *Retrograde:*
 
 ![duplicate](https://github.com/Ash-86/Move-Selection/assets/108089527/cf4bd263-dd33-470e-8b81-dc28dd9299b0)

 *Inversion:*

 ## Download and install
 Download the entire folder, unzip and paste in your MuseScore 4 plugins folder. For more details on installation see [link](https://musescore.org/en/handbook/3/plugins#installation).


 ## feedback
 Please feel free to send any suggestions, bug reports, or just let me know if you find the plugin helpful  :)

 ## Support 
 Making this plugin took time, effort and love.   
 If you appreciate this plugin and find it helpful, you can buy me a beer 
 [here](https://www.paypal.com/donate/?hosted_button_id=BH676KMHGVHC8) :)
