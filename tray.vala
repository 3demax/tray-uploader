using Gtk;
using GLib;
using Soup;
using Notify;

public class Main {

  class AppStatusIcon : Window {
    private StatusIcon trayicon;
    private Menu menuSystem;
    public string image_path;

    public AppStatusIcon(string image_path) {
      /* Create tray icon */
      trayicon = new StatusIcon.from_stock(Stock.GO_UP);
      trayicon.set_tooltip_text (image_path);
      trayicon.set_visible(true);

      trayicon.activate.connect(() => {
        execute("xdg-open " + image_path);
      });

      create_menuSystem();
      trayicon.popup_menu.connect(menuSystem_popup);
      this.image_path = image_path;
    }

    /* Create menu for right button */
    public void create_menuSystem() {
      menuSystem = new Menu();
      
      var show = new ImageMenuItem.from_stock(Stock.EXECUTE, null);
      show.activate.connect(() => {
//        execute("xdg-open " + image_path);
      });
      menuSystem.append(show);
      
      var upload = new ImageMenuItem.from_stock(Stock.GO_UP, null);
      upload.activate.connect(imgur_upload);
      menuSystem.append(upload);
      
      var menuQuit = new ImageMenuItem.from_stock(Stock.QUIT, null);
      menuQuit.activate.connect(Gtk.main_quit);
      menuSystem.append(menuQuit);
      
      menuSystem.show_all();
    }


    public void imgur_upload ()
    {
      message ("Uploading " + this.image_path);

      try {
        var f = File.new_for_path (this.image_path);
        var s = new DataInputStream (f.read());
        var i = f.query_info ("*", FileQueryInfoFlags.NONE);

        int64 fsize = i.get_size ();
        uchar[] data = new uint8[fsize];

        s.read (data);
        s.close ();
        s = null;

        var sess = new Soup.SessionSync ();
          
          sess.add_feature = new Soup.Logger (Soup.LoggerLogLevel.HEADERS, -1);
        
        string image = GLib.Base64.encode(data);
        var values = new HashTable<string, string> (null, null);
        values.set("key", "6af857bfde70d28a6df70be425e453bc");
        values.set("image", image);
        var mess = Soup.Form.request_new_from_hash("POST", "http://api.imgur.com/2/upload.json", values);        
        sess.send_message(mess);
        message("UploadComplete");
        var responce = (string) mess.response_body.data;
        message(">\n" + responce);
        
        var image_url = "";
        var parser = new Json.Parser ();
        parser.load_from_data (responce, -1);

        var root_object = parser.get_root ().get_object ();
        string link = root_object.get_object_member ("upload")
                                    .get_object_member ("links")
                                       .get_string_member ("original");
                                       
        var display = this.get_display ();
        var clipboard = Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
        clipboard.set_text (link, -1);
        
        Notify.init ("Screenshot");
		    var upload = new Notification("Screenshot", this.image_path+"\nuploaded to imgur\n"+link, "dialog-information");
		    upload.show ();
		    Notify.uninit ();
      }
      catch (GLib.Error e) {
//        warning (_("Unable to upload file: %s").printf(e.message));
          warning ("Unable to upload file:" + e.message);
//        Main.window.show_notification (NotifyType.ERROR,
//                                       _("Upload failed"), 
//                                       _("%s was not uploaded OK to %s")
//                                         .printf(path, host));
      }
    }

    /* Show popup menu on right button */
    private void menuSystem_popup(uint button, uint time) {
      menuSystem.popup(null, null, null, button, time);
    }

    private void execute(string cmd) {
        GLib.Process.spawn_command_line_sync(cmd, null, null, null);
    }

    private void about_clicked() {
      var about = new AboutDialog();
      about.set_version("0.0.0");
      about.set_program_name("Imgur uploader");
      about.set_comments("Upload image to imgur.com and get a link in clipboard");
      about.set_copyright("3demax");
      about.run();
      about.hide();
    }
  }

  public static int main (string[] args) {
    Gtk.init(ref args);
    if (args.length >= 2) {
        string image_path = args[1];
        var App = new AppStatusIcon(image_path);
        App.hide();
        Gtk.main();
    } else {
      message("Usage: "+args[0]+" IMAGE_FILE");
      return 1;
    }
    return 0;
  }
}
