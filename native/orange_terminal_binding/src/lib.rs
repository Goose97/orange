use std::io::{self, Write};

use crossterm::event::{self, Event, KeyCode, KeyModifiers};
use crossterm::style::{
    Attribute, Attributes, Color, ContentStyle, PrintStyledContent, StyledContent,
};
use crossterm::terminal::{self, EnterAlternateScreen, LeaveAlternateScreen};
use crossterm::{cursor, execute, queue};
use rustler::{Atom, Encoder, Env, NifStruct, Term};

#[derive(Debug, NifStruct)]
#[module = "Orange.Renderer.Buffer"]
struct Buffer {
    rows: Vec<Vec<Option<Cell>>>,
}

#[derive(Debug, NifStruct)]
#[module = "Orange.Renderer.Cell"]
struct Cell {
    character: String,
    foreground: Option<Atom>,
    background: Option<Atom>,
    modifiers: Vec<Atom>,
}

#[rustler::nif]
fn draw(env: Env, cells: Vec<(Cell, usize, usize)>) {
    let mut writer = io::stdout();
    let mut previous_cursor: Option<(u16, u16)> = None;

    for (cell, x, y) in cells.iter() {
        let should_move = match previous_cursor {
            Some((px, py)) => px != (*x - 1) as u16 || py != *y as u16,
            None => true,
        };

        if should_move {
            queue_command(&mut writer, cursor::MoveTo(*x as u16, *y as u16));
        }

        let content = StyledContent::new(content_style_from_cell(cell, env), &cell.character);
        queue_command(&mut writer, PrintStyledContent(content));

        previous_cursor = Some((*x as u16, *y as u16));
    }

    flush(&mut writer);
}

fn content_style_from_cell(cell: &Cell, env: Env) -> ContentStyle {
    let mut style = ContentStyle::new();
    style.foreground_color = cell
        .foreground
        .as_ref()
        .map(|color| atom_to_color(*color, env));
    style.background_color = cell
        .background
        .as_ref()
        .map(|color| atom_to_color(*color, env));
    style.attributes = Attributes::from(
        cell.modifiers
            .iter()
            .map(|modifier| atom_to_text_attribute(*modifier, env))
            .collect::<Vec<Attribute>>()
            .as_slice(),
    );

    style
}

fn queue_command(writer: &mut impl Write, command: impl crossterm::Command + Clone) {
    loop {
        match queue!(writer, command.clone()) {
            Ok(_) => break,
            Err(err) if err.kind() == io::ErrorKind::WouldBlock => continue,
            Err(err) => panic!("{}", err),
        }
    }
}

fn flush(writer: &mut impl Write) {
    loop {
        match writer.flush() {
            Ok(_) => break,
            Err(err) if err.kind() == io::ErrorKind::WouldBlock => continue,
            Err(err) => panic!("{}", err),
        }
    }
}

fn atom_to_color(atom: Atom, env: Env) -> Color {
    match atom.to_term(env).atom_to_string().unwrap().as_str() {
        "white" => Color::White,
        "black" => Color::Black,
        "grey" => Color::Grey,
        "dark_grey" => Color::DarkGrey,
        "red" => Color::Red,
        "dark_red" => Color::DarkRed,
        "green" => Color::Green,
        "dark_green" => Color::DarkGreen,
        "yellow" => Color::Yellow,
        "dark_yellow" => Color::DarkYellow,
        "blue" => Color::Blue,
        "dark_blue" => Color::DarkBlue,
        "magenta" => Color::Magenta,
        "dark_magenta" => Color::DarkMagenta,
        "cyan" => Color::Cyan,
        "dark_cyan" => Color::DarkCyan,
        _ => Color::Reset,
    }
}

fn atom_to_text_attribute(atom: Atom, env: Env) -> Attribute {
    match atom.to_term(env).atom_to_string().unwrap().as_str() {
        "bold" => Attribute::Bold,
        "dim" => Attribute::Dim,
        "italic" => Attribute::Italic,
        "underline" => Attribute::Underlined,
        "strikethrough" => Attribute::CrossedOut,
        _ => Attribute::Reset,
    }
}

#[derive(Debug, NifStruct)]
#[module = "Orange.Terminal.KeyEvent"]
struct KeyEvent<T: Encoder> {
    code: T,
    modifiers: Vec<Atom>,
}

#[derive(Debug, NifStruct)]
#[module = "Orange.Terminal.ResizeEvent"]
struct ResizeEvent {
    width: u16,
    height: u16,
}

#[rustler::nif(schedule = "DirtyIo")]
fn poll_event(env: Env) -> Term {
    match event::read().unwrap() {
        Event::Key(event) => {
            let code = format_key_code(event.code, env);
            let modifiers = format_key_modifiers(event.modifiers, env);

            if let Some(code) = code {
                let key_event = KeyEvent { code, modifiers };
                key_event.encode(env)
            } else {
                poll_event(env)
            }
        }

        Event::Resize(width, height) => {
            let resize_event = ResizeEvent { width, height };
            resize_event.encode(env)
        }

        _ => poll_event(env),
    }
}

fn format_key_code(code: KeyCode, env: Env) -> Option<Term> {
    let atom = |string: &str| {
        let atom = Atom::from_str(env, string).unwrap();
        Some(atom.to_term(env))
    };

    match code {
        KeyCode::Backspace => atom("backspace"),
        KeyCode::Enter => atom("enter"),
        KeyCode::Left => atom("left"),
        KeyCode::Right => atom("right"),
        KeyCode::Up => atom("up"),
        KeyCode::Down => atom("down"),
        KeyCode::Home => atom("home"),
        KeyCode::End => atom("end"),
        KeyCode::PageUp => atom("page_up"),
        KeyCode::PageDown => atom("page_down"),
        KeyCode::Tab => atom("tab"),
        KeyCode::BackTab => atom("back_tab"),
        KeyCode::Delete => atom("delete"),
        KeyCode::Insert => atom("insert"),
        KeyCode::F(n) => atom(format!("f{}", n).as_str()),
        KeyCode::Char(c) => Some((atom("char"), c.to_string()).encode(env)),
        KeyCode::Null => atom("null"),
        KeyCode::Esc => atom("esc"),
        KeyCode::CapsLock => atom("caps_lock"),
        KeyCode::ScrollLock => atom("scroll_lock"),
        KeyCode::NumLock => atom("num_lock"),
        KeyCode::PrintScreen => atom("print_screen"),
        KeyCode::Pause => atom("pause"),
        KeyCode::Menu => atom("menu"),
        KeyCode::KeypadBegin => atom("keypad_begin"),
        _ => None,
    }
}

fn format_key_modifiers(modifiers: KeyModifiers, env: Env) -> Vec<Atom> {
    let mut result = Vec::new();

    let atom = |string: &str| Atom::from_str(env, string).unwrap();

    if modifiers.contains(KeyModifiers::SHIFT) {
        result.push(atom("shift"));
    }

    if modifiers.contains(KeyModifiers::CONTROL) {
        result.push(atom("control"));
    }

    if modifiers.contains(KeyModifiers::ALT) {
        result.push(atom("alt"));
    }

    if modifiers.contains(KeyModifiers::SUPER) {
        result.push(atom("super"));
    }
    if modifiers.contains(KeyModifiers::HYPER) {
        result.push(atom("hyper"));
    }

    result
}

#[rustler::nif]
fn enter_alternate_screen() {
    execute!(io::stdout(), EnterAlternateScreen).unwrap();
}

#[rustler::nif]
fn leave_alternate_screen() {
    execute!(io::stdout(), LeaveAlternateScreen).unwrap();
}

#[rustler::nif]
fn enable_raw_mode() {
    terminal::enable_raw_mode().unwrap();
}

#[rustler::nif]
fn disable_raw_mode() {
    terminal::disable_raw_mode().unwrap();
}

#[rustler::nif]
fn show_cursor() {
    execute!(io::stdout(), cursor::Show).unwrap();
}

#[rustler::nif]
fn hide_cursor() {
    execute!(io::stdout(), cursor::Hide).unwrap();
}

#[rustler::nif]
fn clear() {
    let mut writer = io::stdout();
    queue_command(&mut writer, terminal::Clear(terminal::ClearType::All));
    queue_command(&mut writer, terminal::Clear(terminal::ClearType::Purge));
    flush(&mut writer);
}

#[rustler::nif]
fn terminal_size(env: Env) -> Term {
    terminal::size().unwrap().encode(env)
}

rustler::init!(
    "Elixir.Orange.Terminal.Binding",
    [
        draw,
        enter_alternate_screen,
        leave_alternate_screen,
        enable_raw_mode,
        disable_raw_mode,
        show_cursor,
        hide_cursor,
        clear,
        poll_event,
        terminal_size,
    ]
);
