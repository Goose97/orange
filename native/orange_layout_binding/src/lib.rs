mod text_utils;

use std::collections::HashMap;
use std::time::SystemTime;

use rustler::{Atom, Env, NifStruct, NifTaggedEnum};
use taffy::prelude::*;

#[derive(Debug, Clone, NifTaggedEnum)]
enum WindowDimension {
    Fixed(usize),
    MaxContent,
}

#[derive(Debug, NifStruct)]
#[module = "Orange.Layout.InputTreeNode"]
struct InputTreeNode {
    id: usize,
    children: TreeNodeChildren<InputTreeNode>,
    style: Option<InputTreeNodeStyle>,
}

#[derive(Debug, NifStruct)]
#[module = "Orange.Layout.InputTreeNode.Style"]
struct InputTreeNodeStyle {
    width: Option<InputLengthPercentage>,
    min_width: Option<InputLengthPercentage>,
    max_width: Option<InputLengthPercentage>,
    height: Option<InputLengthPercentage>,
    min_height: Option<InputLengthPercentage>,
    max_height: Option<InputLengthPercentage>,
    padding: Option<(usize, usize, usize, usize)>,
    margin: Option<(usize, usize, usize, usize)>,
    border: (usize, usize, usize, usize),
    display: Atom,
    flex_direction: Atom,
    flex_grow: Option<usize>,
    flex_shrink: Option<usize>,
    justify_content: Atom,
    align_items: Atom,
    line_wrap: bool,
    row_gap: Option<usize>,
    column_gap: Option<usize>,
    grid_template_rows: Option<Vec<InputGridTrack>>,
    grid_template_columns: Option<Vec<InputGridTrack>>,
    grid_auto_rows: Option<Vec<InputGridTrack>>,
    grid_auto_columns: Option<Vec<InputGridTrack>>,
    grid_row: Option<InputGridLines>,
    grid_column: Option<InputGridLines>,
}

#[derive(Debug, Clone, NifTaggedEnum)]
enum InputLengthPercentage {
    Fixed(usize),
    Percent(f32),
}

#[derive(Debug, Clone, NifTaggedEnum)]
enum InputGridTrackRepeat {
    Fixed(usize),
    Percent(f32),
    Fr(usize),
}

#[derive(Debug, Clone, NifTaggedEnum)]
enum InputGridLines {
    Single(InputGridLine),
    Double(InputGridLine, InputGridLine),
}

#[derive(Debug, Clone, NifTaggedEnum)]
enum InputGridTrack {
    Fixed(usize),
    Percent(f32),
    Fr(usize),
    Auto,
    MinContent,
    MaxContent,
    Repeat(usize, InputGridTrackRepeat),
}

#[derive(Debug, Clone, NifTaggedEnum)]
enum InputGridLine {
    Fixed(usize),
    Span(usize),
    Auto,
}

#[derive(Debug, NifStruct)]
#[module = "Orange.Layout.Span"]
struct Span {
    name: String,
    start_time: u64,
    end_time: u64,
    children: Vec<Span>,
}

fn now_nanos() -> u64 {
    SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap()
        .as_nanos() as u64
}

impl Span {
    fn new(name: &str) -> Self {
        Span {
            name: name.to_string(),
            start_time: now_nanos(),
            end_time: 0,
            children: Vec::new(),
        }
    }

    fn end(&mut self) {
        self.end_time = now_nanos();
    }

    fn add_child(&mut self, child: Span) {
        self.children.push(child);
    }

    fn with_span<T>(&mut self, name: &str, callback: impl FnOnce() -> T) -> T {
        let mut span = Span::new(name);
        let result = callback();
        span.end();
        self.add_child(span);

        return result;
    }
}

#[derive(Debug, NifStruct)]
#[module = "Orange.Layout.OutputTreeNode"]
struct OutputTreeNode {
    id: usize,
    width: f32,
    height: f32,
    x: f32,
    y: f32,
    content_text_lines: Option<Vec<String>>,
    content_size: (f32, f32),
    border: (usize, usize, usize, usize),
    padding: (usize, usize, usize, usize),
    margin: (usize, usize, usize, usize),
    children: TreeNodeChildren<OutputTreeNode>,
}

#[derive(Debug, NifTaggedEnum)]
// A node can either has a single text child or a list of children
enum TreeNodeChildren<T> {
    Text(String),
    Nodes(Vec<T>),
}

#[derive(Debug)]
enum NodeContext {
    Text(String),
}

impl NodeContext {
    fn text(text: &str) -> Self {
        NodeContext::Text(text.to_string())
    }
}

#[derive(Debug, NifStruct)]
#[module = "Orange.Layout.LayoutResult"]
struct LayoutResult {
    root: OutputTreeNode,
    spans: Span,
}

#[rustler::nif(schedule = "DirtyCpu")]
fn layout(
    env: Env,
    root: InputTreeNode,
    window_size: (WindowDimension, WindowDimension),
) -> LayoutResult {
    let mut root_span = Span::new("layout_nif");

    let mut tree: TaffyTree<NodeContext> = TaffyTree::new();
    tree.disable_rounding();

    let mut node_id_mapping = HashMap::<NodeId, &InputTreeNode>::new();
    let mut node_output_lines = HashMap::<NodeId, Vec<String>>::new();

    let taffy_root = root_span.with_span("create_node", || {
        create_node(&mut tree, &root, &mut node_id_mapping, env)
    });

    // Compute layout with some default viewport size
    root_span.with_span("compute_layout", || {
        tree.compute_layout_with_measure(
            taffy_root,
            Size {
                width: window_dimension(window_size.0),
                height: window_dimension(window_size.1),
            },
            |known_dimensions, available_space, node_id, node_context, _style| {
                return match node_context {
                    Some(NodeContext::Text(text)) => {
                        let input_tree_node = node_id_mapping.get(&node_id).unwrap();
                        // Default to true if style is not specified
                        let line_wrap =
                            input_tree_node.style.as_ref().map_or(true, |v| v.line_wrap);

                        let (size, lines) = text_utils::measure_size(
                            text,
                            known_dimensions,
                            available_space,
                            line_wrap,
                        );

                        node_output_lines.insert(node_id, lines);
                        size
                    }

                    _ => Size {
                        width: 0.0,
                        height: 0.0,
                    },
                };
            },
        )
        .unwrap();
    });

    let output_tree = root_span.with_span("collect_nodes", || {
        collect_nodes(&tree, taffy_root, &node_id_mapping, &mut node_output_lines)
    });

    root_span.end();

    LayoutResult {
        root: output_tree,
        spans: root_span,
    }
}

fn window_dimension(size: WindowDimension) -> AvailableSpace {
    match size {
        WindowDimension::Fixed(v) => AvailableSpace::Definite(v as f32),
        WindowDimension::MaxContent => AvailableSpace::MaxContent,
    }
}

fn create_node<'a>(
    taffy: &mut TaffyTree<NodeContext>,
    node: &'a InputTreeNode,
    node_id_mapping: &mut HashMap<NodeId, &'a InputTreeNode>,
    env: Env,
) -> NodeId {
    let style = node_style(&node, env);

    let node_id = match &node.children {
        TreeNodeChildren::Text(text) => taffy
            .new_leaf_with_context(style, NodeContext::text(text))
            .unwrap(),
        TreeNodeChildren::Nodes(nodes) => {
            let child_nodes = nodes
                .iter()
                .map(|node| create_node(taffy, node, node_id_mapping, env))
                .collect::<Vec<NodeId>>();

            taffy.new_with_children(style, &child_nodes).unwrap()
        }
    };

    node_id_mapping.insert(node_id, &node);
    return node_id;
}

fn node_style(node: &InputTreeNode, env: Env) -> Style {
    let mut default_style = Style::default();

    if let Some(style) = &node.style {
        default_style.size = node_size(style, SizeType::Normal);
        default_style.min_size = node_size(style, SizeType::Min);
        default_style.max_size = node_size(style, SizeType::Max);

        default_style.border = Rect {
            top: LengthPercentage::Length(style.border.0 as f32),
            right: LengthPercentage::Length(style.border.1 as f32),
            bottom: LengthPercentage::Length(style.border.2 as f32),
            left: LengthPercentage::Length(style.border.3 as f32),
        };

        if let Some(padding) = style.padding {
            default_style.padding = Rect {
                top: LengthPercentage::Length(padding.0 as f32),
                right: LengthPercentage::Length(padding.1 as f32),
                bottom: LengthPercentage::Length(padding.2 as f32),
                left: LengthPercentage::Length(padding.3 as f32),
            };
        }

        if let Some(margin) = style.margin {
            default_style.margin = Rect {
                top: LengthPercentageAuto::Length(margin.0 as f32),
                right: LengthPercentageAuto::Length(margin.1 as f32),
                bottom: LengthPercentageAuto::Length(margin.2 as f32),
                left: LengthPercentageAuto::Length(margin.3 as f32),
            };
        }

        // Display attributes

        default_style.display = match style
            .display
            .to_term(env)
            .atom_to_string()
            .unwrap()
            .as_str()
        {
            "flex" => Display::Flex,
            "grid" => Display::Grid,
            _ => Display::Flex,
        };

        // Flex properties

        match style
            .flex_direction
            .to_term(env)
            .atom_to_string()
            .unwrap()
            .as_str()
        {
            "row" => default_style.flex_direction = FlexDirection::Row,
            "column" => default_style.flex_direction = FlexDirection::Column,
            "row_reverse" => default_style.flex_direction = FlexDirection::RowReverse,
            "column_reverse" => default_style.flex_direction = FlexDirection::ColumnReverse,
            _ => default_style.flex_direction = FlexDirection::Row,
        };

        if let Some(grow) = style.flex_grow {
            default_style.flex_grow = grow as f32;
        }

        if let Some(shrink) = style.flex_shrink {
            default_style.flex_shrink = shrink as f32;
        }

        match style
            .justify_content
            .to_term(env)
            .atom_to_string()
            .unwrap()
            .as_str()
        {
            "start" => default_style.justify_content = Some(JustifyContent::Start),
            "end" => default_style.justify_content = Some(JustifyContent::End),
            "center" => default_style.justify_content = Some(JustifyContent::Center),
            "space_between" => default_style.justify_content = Some(JustifyContent::SpaceBetween),
            "space_around" => default_style.justify_content = Some(JustifyContent::SpaceAround),
            "space_evenly" => default_style.justify_content = Some(JustifyContent::SpaceEvenly),
            "stretch" => default_style.justify_content = Some(JustifyContent::Stretch),
            _ => (),
        };

        match style
            .align_items
            .to_term(env)
            .atom_to_string()
            .unwrap()
            .as_str()
        {
            "start" => default_style.align_items = Some(AlignItems::Start),
            "end" => default_style.align_items = Some(AlignItems::End),
            "center" => default_style.align_items = Some(AlignItems::Center),
            "stretch" => default_style.align_items = Some(AlignItems::Stretch),
            _ => (),
        };

        // Grid properties
        if let Some(template_rows) = &style.grid_template_rows {
            default_style.grid_template_rows = grid_tracks(template_rows);
        }

        if let Some(template_columns) = &style.grid_template_columns {
            default_style.grid_template_columns = grid_tracks(template_columns);
        }

        if let Some(auto_rows) = &style.grid_auto_rows {
            default_style.grid_auto_rows = non_repeated_grid_tracks(auto_rows);
        }

        if let Some(auto_columns) = &style.grid_auto_columns {
            default_style.grid_auto_columns = non_repeated_grid_tracks(auto_columns);
        }

        match &style.grid_row {
            Some(InputGridLines::Single(line)) => {
                default_style.grid_row = Line {
                    start: grid_line(line),
                    end: auto(),
                }
            }
            Some(InputGridLines::Double(start, end)) => {
                default_style.grid_row = Line {
                    start: grid_line(start),
                    end: grid_line(end),
                }
            }
            None => (),
        }

        match &style.grid_column {
            Some(InputGridLines::Single(line)) => {
                default_style.grid_column = Line {
                    start: grid_line(line),
                    end: auto(),
                }
            }
            Some(InputGridLines::Double(start, end)) => {
                default_style.grid_column = Line {
                    start: grid_line(start),
                    end: grid_line(end),
                }
            }
            None => (),
        }

        // Gap properties
        if let Some(row_gap) = style.row_gap {
            default_style.gap.height = LengthPercentage::Length(row_gap as f32);
        }

        if let Some(column_gap) = style.column_gap {
            default_style.gap.width = LengthPercentage::Length(column_gap as f32);
        }
    }

    return default_style;
}

fn grid_tracks(tracks: &[InputGridTrack]) -> Vec<TrackSizingFunction> {
    tracks
        .iter()
        .map(|v| match v {
            InputGridTrack::Fixed(v) => length(*v as f32),
            InputGridTrack::Percent(v) => percent(*v),
            InputGridTrack::Fr(v) => fr(*v as f32),
            InputGridTrack::Auto => auto(),
            InputGridTrack::MinContent => min_content(),
            InputGridTrack::MaxContent => max_content(),
            InputGridTrack::Repeat(count, track) => {
                let repeat_value = match track {
                    InputGridTrackRepeat::Fixed(v) => length(*v as f32),
                    InputGridTrackRepeat::Percent(v) => percent(*v),
                    InputGridTrackRepeat::Fr(v) => fr(*v as f32),
                };

                repeat(
                    GridTrackRepetition::Count(*count as u16),
                    vec![repeat_value],
                )
            }
        })
        .collect()
}

fn non_repeated_grid_tracks(tracks: &[InputGridTrack]) -> Vec<NonRepeatedTrackSizingFunction> {
    tracks
        .iter()
        .map(|v| match v {
            InputGridTrack::Fixed(v) => length(*v as f32),
            InputGridTrack::Percent(v) => percent(*v),
            InputGridTrack::Fr(v) => fr(*v as f32),
            InputGridTrack::Auto => auto(),
            InputGridTrack::MinContent => min_content(),
            InputGridTrack::MaxContent => max_content(),
            InputGridTrack::Repeat(_count, _track) => unreachable!(),
        })
        .collect()
}

fn grid_line(input_line: &InputGridLine) -> GridPlacement {
    match input_line {
        InputGridLine::Fixed(v) => line(*v as i16),
        InputGridLine::Span(v) => GridPlacement::Span(*v as u16),
        InputGridLine::Auto => GridPlacement::Auto,
    }
}

enum SizeType {
    Normal,
    Min,
    Max,
}

fn node_size(style: &InputTreeNodeStyle, size_type: SizeType) -> Size<Dimension> {
    let width_style = match size_type {
        SizeType::Normal => style.width.clone(),
        SizeType::Min => style.min_width.clone(),
        SizeType::Max => style.max_width.clone(),
    };

    let width = width_style.map_or(Dimension::Auto, |value| match value {
        InputLengthPercentage::Fixed(v) => Dimension::Length(v as f32),
        InputLengthPercentage::Percent(v) => Dimension::Percent(v as f32),
    });

    let height_style = match size_type {
        SizeType::Normal => style.height.clone(),
        SizeType::Min => style.min_height.clone(),
        SizeType::Max => style.max_height.clone(),
    };

    let height = height_style.map_or(Dimension::Auto, |value| match value {
        InputLengthPercentage::Fixed(v) => Dimension::Length(v as f32),
        InputLengthPercentage::Percent(v) => Dimension::Percent(v as f32),
    });

    Size { width, height }
}

fn collect_nodes(
    tree: &TaffyTree<NodeContext>,
    node_id: NodeId,
    node_id_mapping: &HashMap<NodeId, &InputTreeNode>,
    node_output_lines: &mut HashMap<NodeId, Vec<String>>,
) -> OutputTreeNode {
    let tree_layout = tree.layout(node_id).unwrap();

    // Add current node
    let node_context = tree.get_node_context(node_id);

    let children = match node_context {
        // Invariant: a node can either have a single text child or a list of node children
        Some(NodeContext::Text(text)) => TreeNodeChildren::Text(text.clone()),
        None => {
            let children = tree
                .children(node_id)
                .unwrap()
                .iter()
                .map(|id| collect_nodes(tree, *id, node_id_mapping, node_output_lines))
                .collect::<Vec<OutputTreeNode>>();
            TreeNodeChildren::Nodes(children)
        }
    };

    let root = OutputTreeNode {
        id: node_id_mapping.get(&node_id).map(|v| v.id).unwrap(),
        width: tree_layout.size.width,
        height: tree_layout.size.height,
        x: tree_layout.location.x,
        y: tree_layout.location.y,
        content_text_lines: node_output_lines.remove(&node_id),
        content_size: (
            tree_layout.content_size.width,
            tree_layout.content_size.height,
        ),
        border: rect_to_tuple(tree_layout.border),
        padding: rect_to_tuple(tree_layout.padding),
        margin: rect_to_tuple(tree_layout.margin),
        children,
    };

    return root;
}

fn rect_to_tuple(value: Rect<f32>) -> (usize, usize, usize, usize) {
    let left = value.left as usize;
    let right = value.right as usize;
    let top = value.top as usize;
    let bottom = value.bottom as usize;

    (top, right, bottom, left)
}

rustler::init!("Elixir.Orange.Layout.Binding", [layout]);
