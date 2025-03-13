# Pitch and Rhythm Transformer: *Plugin for MuseScore*

A MuseScore 3.x/4.x plugin that performs several rhythm and pitch transformation including rotation, retrograde, inversion, scale mapping, and pitch mapping. Supports multiple voices and staff selections.

## Features
 - Ability to transform rhythm or pitches separately.
 - Tuplets are handeled correctly no matter the internal subdivision and number of notes inside the tuplet. 
 - In the case of transposed instruments, transformations applied in one pitch mode (concert or score pitch) are correctly mirrored in the other mode. 
 - Pivot notes are read and determined according to the active concert/score pitch mode. 


## Usage
 - Rotation: Choose the number of steps by which to rotate pitches, rhythm, or both. A positive number for forward rotation, negative for backwards.
 - Retrograde: Choose to reverse pitches, rhythm, or both. 
 - Inversion: Select the type of inversion (diatonic or chromatic) and choose to invert by a specific pitch or by outermost pitches.
 - **Caution:** A diatonic inversion applied to non-diatonic notes disregards accidentals. ex: key of C Maj, Both Db and D# are treated as D natural. This is not a bug but is due to a concious choice of implementation.
 - Map Scale: choose key and scale unto wich you would like to map the selection. Non scale notes are mapped to the nearest scale note respecting note names n case of equidistant pitches, ex: Db is considered closer to D than to C.
 - Map Pitch: Choose pitch (with or without enharmonic equivalents) at specific octave or all octaves and map it to any pitch at a specific octave or nearest one above or below. 

 ## Demo
 *Rotation:*   
 ![rotate](https://github.com/Ash-86/Pitch-and-Rhythm-Transformer/assets/108089527/47eac075-9f28-44db-832e-3804f7129803) 

 *Retrograde:*
 ![reverse](https://github.com/Ash-86/Pitch-and-Rhythm-Transformer/assets/108089527/43d5e667-f533-4a68-bd29-86c848a2758a) 

 *Inversion:*
![invert](https://github.com/Ash-86/Pitch-and-Rhythm-Transformer/assets/108089527/6f0d119f-8525-4306-b854-9df0c6457efc)

*Map Scale*

*Map Pitches:*


 ## Download and install
 Download the entire folder, unzip and paste in your MuseScore 4 plugins folder. For more details on installation see [link](https://musescore.org/en/handbook/3/plugins#installation).


 ## feedback
 Please feel free to send any suggestions, bug reports, or just let me know if you find the plugin helpful  :)

 ## Support 
 Making this plugin took time, effort and love.   
 If you appreciate this plugin and find it helpful, show me some love by giving it a star. If you like, you can also buy me a beer 
 [here](https://www.paypal.com/donate/?hosted_button_id=BH676KMHGVHC8) :)
