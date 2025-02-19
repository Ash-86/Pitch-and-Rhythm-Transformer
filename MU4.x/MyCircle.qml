import QtQuick 
import QtQuick.Controls 
import Muse.UiComponents
import Muse.Ui

      
Item{   
   id: root
   width: 180
   height: 180
   property var lnote: null
   property var hnote: null
   property var cycleOfFifths:["D♮","A♮","E♮","B♮","F♯","D♭","A♭","E♭","B♭","F♮","C♮","G♮"];
   
   Canvas {
      id: canvas
      width: 180
      height: 180 
      
      property var outRadius : (width) / 2 // the radius of the pizza
      property var innRadius: outRadius-30
      property var centerRadius: (outRadius+innRadius)/2 
      
      function drawAxis(index, hovered, selectedNotes, down) {
         if (hovered || selectedNotes){
            var total=6 //number of slices
            var ctx = canvas.getContext("2d")
            
            var cx = width / 2 // the center x coordinate of the pizza
            var cy = height / 2 // the center y coordinate of the pizza

            // Set the stroke and fill styles
            ctx.strokeStyle = down? ui.theme.backgroundSecondaryColor : (selectedNotes? ui.theme.accentColor : ui.theme.buttonColor)  // 
            
            // Start a new path  
            const angle = (index * 2 * Math.PI) / 12;
            const startX = cx - (outRadius) * Math.cos(angle);
            const startY = cy - (outRadius) * Math.sin(angle);
            const endX = cx + (outRadius) * Math.cos(angle);
            const endY = cy + (outRadius) * Math.sin(angle);

            ctx.beginPath();
            ctx.moveTo(startX, startY);
            ctx.lineTo(endX, endY);
            ctx.lineWidth = hovered ? 2 : 2 // change the stroke width based on the hovered state
            ctx.stroke();      
      
            ctx.closePath()
         }         
      } //end  func drawAxis

      MouseArea {
         id: mouseArea
         anchors.fill: parent
         hoverEnabled: true
         
         property int hoveredIndex:-1 // store the index of the hovered slice
         property int index
         property var down: false
         property var selectedNotes:[0,0,0,0,0,0,0,0,0,0,0,0] 
         property var sum:0
         
         onPositionChanged: {
            var ctx = canvas.getContext("2d")
            var angle = 2 * Math.PI / 12 // the angle of each slice
            var OutRadius = width / 2 // the radius of the pizza
            var cx = width / 2 // the center x coordinate of the pizza
            var cy = height / 2 // the center y coordinate of the pizza

            // Get the mouse position relative to the center of the pizza
            var dx = mouseX - cx
            var dy = mouseY - cy

            // Get the distance and angle from the center of the pizza
            var distance = Math.sqrt(dx * dx + dy * dy)
            var mouseAngle = Math.atan2(dy, dx)

            // Normalize the mouse angle to [0, 2 * Math.PI)
            if (mouseAngle < 0) {
               mouseAngle += 2 * Math.PI
            }
            // Check if the mouse is inside the pizza circle
            if (distance < (parent.outRadius+parent.innRadius)/2) {
               // Find the index of the slice that contains the mouse position
               index = Math.floor((mouseAngle + 2*Math.PI/24) / (angle))  %12                   
            }
            else{
               index=-1               
            }
            if (index!=hoveredIndex){  
               hoveredIndex = index
               console.log("hovered index:", mouseArea.hoveredIndex)
               canvas.requestPaint ()
            }  
            
         }//on position changed
         onPressed: { 
            down=true
            canvas.requestPaint()
            console.log("clickes on", mouseArea.hoveredIndex)            
            
         }
         onReleased:{ 
            if (selectedNotes[index]==0 ){                  
               if (sum==1){
                  selectedNotes=[0,0,0,0,0,0,0,0,0,0,0,0]
                  selectedNotes[index]=1
                  sum=1
               }
               else{
                     selectedNotes[index]=1
                     sum++ 
               }
               root.lnote= root.cycleOfFifths[index]  
               //root.lnote.accidental= root.cycleOfFifths[index][1] 
               
               root.hnote= root.cycleOfFifths[(index+1)%12] 
               //root.hnote.accidental= root.cycleOfFifths[(index+1)%12][1] 
               console.log(root.lnote, root.hnote) 
            }
            else if (selectedNotes[index]==1){
               selectedNotes[index]=0
               sum--
               root.lnote= null
               root.hnote= null
               console.log(root.lnote, root.hnote)   
            }
            down=false 
            canvas.requestPaint()            
         }
            
      }//mouseArea
      onPaint: {
         var ctx = canvas.getContext("2d")
         ctx.clearRect(0, 0, width, height)
         for (var i = 0; i < 12; i++) {                    
            //drawSlice(i, false, mouseArea.selectedNotes[i], false)
            drawAxis(i, false, mouseArea.selectedNotes[i], false)
         }

         if (mouseArea.hoveredIndex!=-1 ) {
            // Draw only the current slice with hovered state
            //drawSlice(mouseArea.hoveredIndex, true,  mouseArea.selectedNotes[mouseArea.hoveredIndex], mouseArea.down )                    
            drawAxis(mouseArea.hoveredIndex, true,  mouseArea.selectedNotes[mouseArea.hoveredIndex], mouseArea.down )      
         }   
      }//paint
   }///canvas

   Repeater {
      model: ["C", "G", "D", "A", "E", "B", "F♯/G♭", "D♭", "A♭", "E♭", "B♭", "F"]
      delegate: Item {
         property var n: (index + 9 ) % 12
         x: parent.width/2 + Math.cos(2*Math.PI*n/12 + Math.PI/12 )*canvas.centerRadius
         y: parent.height/2 + Math.sin(2*Math.PI*n/12 + Math.PI/12)*canvas.centerRadius 
         StyledTextLabel {
            anchors.centerIn: parent
            text: modelData  
            font: ui.theme.largeBodyFont              
         }
      }
   }
}// end item
      
