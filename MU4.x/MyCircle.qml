import QtQuick 
import QtQuick.Controls 
import Muse.UiComponents
import Muse.Ui
      
Item {   
   id: root
   width: 180
   height: 180
   property var lnote: null
   property var hnote: null
   property var cycleOfFifths:["D♮","A♮","E♮","B♮","F♯","D♭","A♭","E♭","B♭","F♮","C♮","G♮"]
   
   Canvas {
      id: canvas
      width: 180
      height: 180 
      
      property var outRadius : (width) / 2 
      property var innRadius: outRadius-30
      property var centerRadius: (outRadius+innRadius)/2 
      property var cx: width / 2   // center x 
      property var cy: height / 2   // center y 
      property var angle: 2 * Math.PI / 12

      function drawAxis(index, hovered, selectedNotes, down) {
         if (hovered || selectedNotes){            
            var ctx = canvas.getContext("2d")            
            var startX = cx - (outRadius) * Math.cos(angle * index)
            var startY = cy - (outRadius) * Math.sin(angle * index)
            var endX = cx + (outRadius) * Math.cos(angle * index)
            var endY = cy + (outRadius) * Math.sin(angle * index)

            ctx.strokeStyle = down? ui.theme.backgroundSecondaryColor : (selectedNotes? ui.theme.accentColor : ui.theme.buttonColor)  // 
            ctx.lineWidth = hovered ? 2 : 2
            ctx.beginPath()
            ctx.moveTo(startX, startY)
            ctx.lineTo(endX, endY)
            ctx.stroke()
            ctx.closePath()
         }         
      } 

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
            
            // Get the mouse position relative to the center of the pizza
            var dx = mouseX - canvas.cx
            var dy = mouseY - canvas.cy

            // Get the distance and angle from the center of the pizza
            var distance = Math.sqrt(dx * dx + dy * dy)
            var mouseAngle = Math.atan2(dy, dx)

            // Normalize the mouse angle to [0, 2 * Math.PI)
            if (mouseAngle < 0) {
               mouseAngle += 2 * Math.PI
            }
            // Check if the mouse is inside the pizza circle
            if (distance < canvas.centerRadius) {
               // Find the index of the slice that contains the mouse position
               index = Math.floor((mouseAngle + canvas.angle/2) / (canvas.angle))  %12                   
            }
            else{
               index=-1               
            }
            if (index!=hoveredIndex){  
               hoveredIndex = index
               console.log("hovered index:", mouseArea.hoveredIndex)
               canvas.requestPaint ()
            }              
         }
         onPressed: { 
            down=true
            canvas.requestPaint()
            console.log("clickes on", mouseArea.hoveredIndex)                        
         }
         onReleased: { 
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
      }
      onPaint: {
         var ctx = canvas.getContext("2d")
         ctx.clearRect(0, 0, width, height)

         for (var i = 0; i < 12; i++) { 
            drawAxis(i, false, mouseArea.selectedNotes[i], false)
         }
         if (mouseArea.hoveredIndex!=-1 ) {
            // Draw only the current slice with hovered state                           
            drawAxis(mouseArea.hoveredIndex, true,  mouseArea.selectedNotes[mouseArea.hoveredIndex], mouseArea.down )      
         }   
      }
   }

   Repeater {
      model: ["C", "G", "D", "A", "E", "B", "F♯/G♭", "D♭", "A♭", "E♭", "B♭", "F"]
      delegate: Item {
         property var n: (index + 9 ) % 12
         x: parent.width/2 + Math.cos(n*canvas.angle + canvas.angle/2 )*canvas.centerRadius
         y: parent.height/2 + Math.sin(n*canvas.angle + canvas.angle/2)*canvas.centerRadius 
         StyledTextLabel {
            anchors.centerIn: parent
            text: modelData  
            font: ui.theme.largeBodyFont              
         }
      }
   }
}
      
