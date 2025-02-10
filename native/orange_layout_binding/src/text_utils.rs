use taffy::prelude::*;
use unicode_segmentation::UnicodeSegmentation;

pub fn measure_size(
    text: &str,
    known_dimensions: Size<Option<f32>>,
    available_space: Size<AvailableSpace>,
    line_wrap: bool,
) -> (Size<f32>, Vec<String>) {
    let text_sizes = |max_width: f32| -> (Size<f32>, Vec<String>) {
        let mut lines = Vec::new();
        let mut current_line = String::new();
        let words = split_with_whitespaces(text);

        for (word, whitespaces_count) in words {
            let word_width = graphemes_count(word);

            // Add the next word and the whitespaces
            let current_width = graphemes_count(&current_line);
            let new_width = current_width + word_width + whitespaces_count;

            if current_width == 0 || new_width as f32 <= max_width {
                // If the line is empty, always add the word no matter what
                // Otherwise, add the word only if it fits
                current_line.push_str(word);
                current_line.push_str(&" ".repeat(whitespaces_count));
            } else {
                // Width is too long, move to next line
                lines.push(current_line);
                current_line = word.to_string();
                current_line.push_str(&" ".repeat(whitespaces_count));
            }
        }

        if graphemes_count(&current_line) > 0 {
            lines.push(current_line);
        }

        let max_line_width = lines
            .iter()
            .map(|line| graphemes_count(line))
            .max()
            .unwrap_or(0);

        (
            Size {
                width: max_line_width as f32,
                height: lines.len() as f32,
            },
            lines,
        )
    };

    let single_line = (
        Size {
            width: graphemes_count(text) as f32,
            height: 1.0,
        },
        vec![text.to_owned()],
    );

    if !line_wrap {
        return single_line;
    }

    let result = match known_dimensions.width {
        Some(w) => text_sizes(w),
        None => match available_space.width {
            // Min content renders each word on a single line
            AvailableSpace::MinContent => text_sizes(0.0),
            AvailableSpace::MaxContent => single_line,
            AvailableSpace::Definite(width) => text_sizes(width),
        },
    };

    return result;
}

fn graphemes_count(text: &str) -> usize {
    text.graphemes(true).count()
}

fn split_with_whitespaces(text: &str) -> Vec<(&str, usize)> {
    let mut result = Vec::new();
    let mut word_start = None;
    let mut leading_whitespace_count = 0;
    let chars: Vec<(usize, char)> = text.char_indices().collect();

    // Handle leading whitespaces
    for (idx, c) in chars.iter() {
        if c.is_whitespace() {
            leading_whitespace_count += 1;
        } else {
            if leading_whitespace_count > 0 {
                result.push(("", leading_whitespace_count));
            }
            word_start = Some(*idx);
            break;
        }
    }

    // Process rest of string
    let mut whitespace_count = 0;
    for (idx, c) in chars.iter().skip(leading_whitespace_count) {
        if c.is_whitespace() {
            match word_start {
                Some(start) => {
                    result.push((&text[start..*idx], 0));
                    word_start = None;
                    whitespace_count = 1;
                }

                None => whitespace_count += 1,
            }
        } else {
            if word_start.is_none() {
                if whitespace_count > 0 {
                    // Update previous word's whitespace count
                    if let Some(last) = result.last_mut() {
                        last.1 = whitespace_count;
                    }
                }
                word_start = Some(*idx);
                whitespace_count = 0;
            }
        }
    }

    // Handle the last word
    if whitespace_count > 0 {
        // Leading whitespaces
        if let Some(last) = result.last_mut() {
            last.1 = whitespace_count;
        }
    } else {
        // No leading whitespaces
        let start = word_start.unwrap();
        result.push((&text[start..], 0));
    }

    result
}

#[cfg(test)]
mod tests {
    mod split_with_whitespaces {
        use super::super::*;

        #[test]
        fn single_space() {
            assert_eq!(
                split_with_whitespaces("foo bar baz"),
                vec![("foo", 1), ("bar", 1), ("baz", 0)]
            );
        }

        #[test]
        fn multiple_spaces() {
            assert_eq!(
                split_with_whitespaces("foo  bar    baz"),
                vec![("foo", 2), ("bar", 4), ("baz", 0)]
            );
        }
        #[test]
        fn with_leading_whitespaces() {
            assert_eq!(split_with_whitespaces(" foo"), vec![("", 1), ("foo", 0),]);

            assert_eq!(
                split_with_whitespaces("   foo bar    baz"),
                vec![("", 3), ("foo", 1), ("bar", 4), ("baz", 0)]
            );
        }
        #[test]
        fn with_trailing_whitespaces() {
            assert_eq!(split_with_whitespaces("foo "), vec![("foo", 1)]);

            assert_eq!(
                split_with_whitespaces("foo bar    baz  "),
                vec![("foo", 1), ("bar", 4), ("baz", 2)]
            );
        }
    }
}
