package application;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URI;
import java.util.ArrayList;
import java.util.Iterator;

import javax.imageio.ImageIO;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.NodeList;
import org.w3c.dom.Node;
import org.w3c.dom.Text;

import javafx.animation.PauseTransition;
import javafx.application.Application;
import javafx.application.Platform;
import javafx.concurrent.Worker.State;
import javafx.embed.swing.SwingFXUtils;
import javafx.scene.Scene;
import javafx.scene.image.WritableImage;
import javafx.scene.web.WebEngine;
import javafx.scene.web.WebView;
import javafx.stage.Stage;
import javafx.scene.Group;
import javafx.util.Duration;
import javafx.scene.layout.VBox;
import javafx.scene.control.Button;
import javafx.stage.FileChooser;
import javafx.event.ActionEvent;
import javafx.event.EventHandler;

public class Fx extends Application {
	static int width;
	static int height;
	static String fname;
	static String oname;
	static boolean snapshot;
	
ArrayList<Node> removeButtons(WebEngine webEngine) {
		Document document = webEngine.getDocument();
        Element elementById = document.getElementById("figureArea");
    	NodeList childNodes = elementById.getChildNodes();
    	ArrayList<Node> arrayList = new ArrayList<Node>();
    	   for (int i=0;i<childNodes.getLength();i++) { 
    		   Node node = childNodes.item(i);
    		   if (node.hasAttributes()) {
    		     NamedNodeMap attributes = node .getAttributes();
    		     if (
                 attributes.getNamedItem("class")!=null && attributes.getNamedItem("class").getNodeValue().equals("button")) {
    	  	         arrayList.add(childNodes.item(i));
    		     }
    	        }	
    	   }
    	   for (Iterator<Node> iterator = arrayList.iterator(); iterator.hasNext();) {
			Node n = iterator.next();
			elementById.removeChild(n);
		   }
    	  return arrayList;
	}

	@Override
	public void start(Stage primaryStage) {
		primaryStage.setMinWidth(width);
		primaryStage.setMinHeight(height);
		System.out.println("start:" + fname + ":" + height);
		// Group root = new Group();
		final WebView wb = new WebView();
		final WebEngine webEngine = wb.getEngine();
		final Button buttonSave = new Button("Save");
		wb.setMinHeight(height);
		VBox box = new VBox(wb);	
		final Scene scene = new Scene(box);
		if (!snapshot) box.getChildren().add(buttonSave);
		buttonSave.setOnAction(new EventHandler<ActionEvent>(){
            @Override
           public void handle(ActionEvent arg0) {
               box.getChildren().remove(buttonSave);
               ArrayList<Node> arrayList = removeButtons(webEngine);
               FileChooser fileChooser = new FileChooser();
               fileChooser.setInitialDirectory(new File(System.getProperty("user.home")));
               fileChooser.setInitialFileName("shapes.png");
               File file = fileChooser.showSaveDialog(primaryStage);
               WritableImage img = new WritableImage(width, height);
			   scene.snapshot(img);
			   try {
                  ImageIO.write(SwingFXUtils.fromFXImage(img, null), "png", file);
			   } catch (Exception s) {
				}
			   box.getChildren().add(buttonSave);
			   Document document = webEngine.getDocument();
		       Element elementById = document.getElementById("body");
			   for (int i = 0; i < arrayList.size(); i++) {
			      Node n = arrayList.get(i);
				  elementById.appendChild(n);
			      }
           }
       });
		
		webEngine.getLoadWorker().stateProperty().addListener((obs, oldState, newState) -> {
			if (newState == State.SUCCEEDED) {
				if (snapshot) {
					removeButtons(webEngine);
					final PauseTransition pause = new PauseTransition(Duration.millis(500));
					pause.setOnFinished(e -> {
						WritableImage img = new WritableImage(width, height);
						scene.snapshot(img);
						// System.out.println("after snapshot");
						try {
							File file = new File(new URI(oname));
							ImageIO.write(SwingFXUtils.fromFXImage(img, null), "png", file);
							Platform.exit();
						} catch (Exception s) {
						}
					});
					pause.play();
				}
			}
		});
        webEngine.load(fname);
		primaryStage.setScene(scene);
		System.out.println("end");
		primaryStage.show();

	}

	String htmlInput() throws IOException {
		BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
		String r = "";
		try {
			StringBuilder sb = new StringBuilder();
			//System.out.println("HALLO");
			String line = br.readLine();
			while (line != null) {
				System.out.println(line);
				sb.append(line);
				sb.append(System.lineSeparator());
				line = br.readLine();
			}
			r = sb.toString();
		} finally {
			br.close();
		}
		return r;
	}

	public static void main(String[] args) {
		fname = args[0];
		oname = args[1];
		width = Integer.parseInt(args[2]);
		height = Integer.parseInt(args[3]);
		snapshot = Boolean.parseBoolean(args[4]);
		launch();
	}
}
