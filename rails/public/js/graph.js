function sketchProc(processing) {
	const WIDTH = Number($('graph_main').getAttribute('width'));
	const HEIGHT = Number($('graph_main').getAttribute('height'));

	var refresh = function() {
		processing.stroke(250, 240, 230);
		processing.fill(250, 240, 230);
		processing.rect(0, 0, WIDTH, HEIGHT);
	}

  processing.setup = function() {
	  processing.size(WIDTH, HEIGHT);
	  processing.background(250, 240, 230);
  }

  processing.draw = function() {
		//Host.position_update();

		refresh();

    Route.preDraw(processing);
    
		Line.draw(processing);
    Switch.draw(processing);
		Host.draw(processing);
  }

  processing.mouseClicked = function() {
    Switch.mouseClicked(processing.mouseX, processing.mouseY);
  }

  processing.mousePressed = function() {
    Switch.mousePressed(processing.mouseX, processing.mouseY);
    Host.mousePressed(processing.mouseX, processing.mouseY);
  }

  processing.mouseReleased = function() {
    Switch.mouseReleased(processing.mouseX, processing.mouseY);
    Host.mouseReleased(processing.mouseX, processing.mouseY);
  }
}
