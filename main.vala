using Gtk;
using GLib;

public class Main : Window {
	Gtk.Button button1; //Download
	Gtk.Button button2; //Settings
	Gtk.Entry entry1;
	Gtk.TextView textview1;
	Gtk.ProgressBar pbar1;

	public Main() {

		//Window-Settings
		this.title = "SaveTube";
		this.border_width = 10;
		this.window_position = WindowPosition.CENTER;
		this.destroy.connect(Gtk.main_quit);
		this.set_default_size(400,200);
		this.set_resizable(false);

		//Generating Ui-Elements
		button1 = new Gtk.Button.with_label("Download");
		button1.clicked.connect(() => {
   			on_button1_clicked();
		});

		button2 = new Gtk.Button();
		var image = new Gtk.Image.from_icon_name("settings", IconSize.LARGE_TOOLBAR);
		button2.add(image);
		button2.clicked.connect(() => {
			on_button2_clicked();
		});

		entry1 = new Gtk.Entry();
		entry1.set_placeholder_text("Paste your url..");

		textview1 = new Gtk.TextView();
		textview1.set_editable(false);

		pbar1 = new Gtk.ProgressBar();

		//Layout
		var hbar = new HeaderBar();
		hbar.set_title("SaveTube");
		hbar.set_has_subtitle(false);
		hbar.set_show_close_button(true);
		this.set_titlebar(hbar);
		hbar.pack_start(button1);
		hbar.pack_end(button2);

		var hbox = new Box(Orientation.HORIZONTAL, 10);
		hbox.pack_start(entry1);

		var vbox = new Box(Orientation.VERTICAL, 10);
		vbox.pack_start(hbox);
		vbox.pack_start(textview1);
		vbox.pack_start(pbar1);

		this.add(vbox);
	}

	public static int main(string[] args){
		Gtk.init(ref args);

		Main window = new Main();
		window.show_all();

		Gtk.main();
		return 0;
	}


	//Setters for GUI


	//Action-Methods
	public void on_button1_clicked() {
		string command = "youtube-dl";
		string url = entry1.get_text();

		execute_command_async_with_pipes.begin (new string[]{command, url, "--newline"}, (obj, async_res) => {
			GLib.message("Done");
		});
	}

	public void on_button2_clicked() {

	}

	/**
		Processes the command string from youtube-dl and reacts accordingly.
	*/
	public void processCommandString(string str_command) {
		if(str_command.contains("Destination:")) {
			//Get the title
			int pos_title = str_command.index_of(":");
			string str_title = str_command.substring(pos_title+2, str_command.last_index_of("-")-pos_title-2);

			//Set textview1 to title;
			entry1.set_text("");
			textview1.buffer.text = str_title;
		}
		else if(str_command.contains("%")) {
			//Get the progress number
			int pos_progress = str_command.index_of("%")-5;
			string str_progress = str_command.substring(pos_progress,5);

			//Prepare the string for conversion
			str_progress = str_progress.strip();
			str_progress = str_progress.replace(".","");
			str_progress = "0." + str_progress;

			//Set pbar1 to current progress
			pbar1.set_fraction(double.parse(str_progress));
		}
	}

	//Spawn corresponding Pipes and return the output-line back as string
	public async void execute_command_async_with_pipes (string[] spawn_args) {
		var launcher = new SubprocessLauncher (SubprocessFlags.STDOUT_PIPE);

		Subprocess subprocess = launcher.spawnv (spawn_args);
		var input_stream = subprocess.get_stdout_pipe ();

		var data_input_stream = new DataInputStream (input_stream);
		while (true) {
			string str_return = yield data_input_stream.read_line_async ();
			if (str_return == null) {
				break;
			} else {
				processCommandString(str_return);
			}
		}

	}

}
