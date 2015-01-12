using Gtk;
using GLib;

public class Main : Window {
	Gtk.Button button1; //Download
	Gtk.Button button2; //Settings WIP
	Gtk.ComboBoxText cbox1;
	Gtk.Entry entry1;
	Gtk.ListBox listbox1;
	Gtk.ProgressBar pbar1;

	public Main() {

		//Window-Settings
		this.title = "SaveTube";
		this.border_width = 10;
		this.window_position = WindowPosition.CENTER;
		this.destroy.connect(Gtk.main_quit);
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

		cbox1 = new Gtk.ComboBoxText();
		cbox1.append_text("Video");
		cbox1.append_text("Mp3");
		cbox1.active = 0;
		cbox1.changed.connect(() => {
			//cbox1_changed();
		});

		entry1 = new Gtk.Entry();
		entry1.set_placeholder_text("Paste your url..");

		//Setting up TextView with TextBuffer
		listbox1 = new Gtk.ListBox();
		listbox1.set_size_request(500, 100);

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
		hbox.pack_start(cbox1, false);
		hbox.pack_start(entry1);

		var vbox = new Box(Orientation.VERTICAL, 10);
		vbox.pack_start(hbox);
		vbox.pack_start(listbox1);
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
	public void on_button1_clicked () {
		execute_command_async_with_pipes.begin (get_command(), (obj, async_res) => {
			GLib.message("Done");
		});
	}

	public void on_button2_clicked () {

	}


	/**
		Finds the corresponding command options and returns it as string[].
	*/
	public string[] get_command () {
		var array = new GenericArray<string> ();
		array.add ("youtube-dl");
		array.add (entry1.get_text());
		array.add ("--newline");
		array.add ("--ignore-errors");

		string str_option = cbox1.get_active_text ();
		if (str_option == "Video") {

		}
		else if (str_option == "Mp3") {
			array.add ("--extract-audio");
			array.add ("--audio-format");
			array.add ("mp3");
		}

		//Convert GenericArray to builtin array and return
		string[] builtin_array = array.data;
		return builtin_array;
	}

	/**
		Processes the command string from youtube-dl and reacts accordingly.
	*/
	public void processCommandString(string str_command) {
		if(str_command.contains("[download] Destination")) {
			//Get the title
			int pos_title = str_command.index_of(":");
			string str_title = str_command.substring(pos_title+2, str_command.last_index_of("-")-pos_title-2);

			//Set textview1 to title;
			entry1.set_text("");

			if (str_title.length > 65) {
				str_title = str_title.slice(0, 65) + "...";
			}

			var label = new Gtk.Label(str_title);
			label.set_halign(Align.START);
			listbox1.add(label);
		}
		else if(str_command.contains("%")) {
			//Get the progress number
			int pos_progress = str_command.index_of("%")-5;
			string str_progress = str_command.substring(pos_progress,5);

			//Prepare the string for conversion
			str_progress = str_progress.strip();

			//Convert to double and set pbar1 to current progress
			double d_progress = double.parse(str_progress)/100;
			pbar1.set_fraction(d_progress);

			if (d_progress == 1) {
				//TODO DONE, just a placeholder atm
				var label = new Gtk.Label("DONE!");
				label.set_halign(Align.START);
				listbox1.add(label);
			}
		}
		else if (str_command.contains("ERROR")) {
			//Doesn't work yet, can't catch ytdl errors
		}

		listbox1.show_all();
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
