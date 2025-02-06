use std::collections::HashMap;

use rustler::{Atom, Env, NifStruct, NifTaggedEnum};
use taffy::prelude::*;

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
    height: Option<InputLengthPercentage>,
    padding: (usize, usize, usize, usize),
    margin: (usize, usize, usize, usize),
    border: (usize, usize, usize, usize),
    display: Atom,
    flex_direction: Atom,
    flex_grow: Option<usize>,
    flex_shrink: Option<usize>,
    justify_content: Atom,
    align_items: Atom,
    line_wrap: bool,
    grid_template_rows: Option<Vec<InputLengthPercentage>>,
    grid_template_columns: Option<Vec<InputLengthPercentage>>,
    grid_auto_rows: Option<InputLengthPercentage>,
    grid_auto_columns: Option<InputLengthPercentage>,
    grid_row: Option<(usize, usize)>,
    grid_column: Option<(usize, usize)>,
}

#[derive(Debug, Clone, NifTaggedEnum)]
enum InputLengthPercentage {
    Fixed(usize),
    Percent(f32),
}

#[derive(Debug, NifStruct)]
#[module = "Orange.Layout.OutputTreeNode.FourValues"]
struct OutputTreeNodeFourValues {
    left: usize,
    right: usize,
    top: usize,
    bottom: usize,
}

impl From<Rect<f32>> for OutputTreeNodeFourValues {
    fn from(value: Rect<f32>) -> Self {
        Self {
            left: value.left as usize,
            right: value.right as usize,
            top: value.top as usize,
            bottom: value.bottom as usize,
        }
    }
}

#[derive(Debug, NifStruct)]
#[module = "Orange.Layout.OutputTreeNode"]
struct OutputTreeNode {
    id: usize,
    width: usize,
    height: usize,
    x: usize,
    y: usize,
    content_size: (usize, usize),
    border: OutputTreeNodeFourValues,
    padding: OutputTreeNodeFourValues,
    margin: OutputTreeNodeFourValues,
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

#[rustler::nif]
fn layout(env: Env, root: InputTreeNode, window_size: (usize, usize)) -> OutputTreeNode {
    let mut tree: TaffyTree<NodeContext> = TaffyTree::new();

    let mut node_id_mapping = HashMap::<NodeId, &InputTreeNode>::new();
    let taffy_root = create_node(&mut tree, &root, &mut node_id_mapping, env);

    // Compute layout with some default viewport size
    tree.compute_layout_with_measure(
        taffy_root,
        Size {
            width: AvailableSpace::Definite(window_size.0 as f32),
            height: AvailableSpace::Definite(window_size.1 as f32),
        },
        |known_dimensions, available_space, node_id, node_context, _style| {
            return match node_context {
                Some(NodeContext::Text(text)) => {
                    let input_tree_node = node_id_mapping.get(&node_id).unwrap();
                    // Default to true if style is not specified
                    let line_wrap = input_tree_node.style.as_ref().map_or(true, |v| v.line_wrap);
                    measure_text_sizes(text, known_dimensions, available_space, line_wrap)
                }

                _ => Size {
                    width: 0.0,
                    height: 0.0,
                },
            };
        },
    )
    .unwrap();

    collect_nodes(&tree, taffy_root, &node_id_mapping)
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
            .new_leaf_with_context(style.clone(), NodeContext::text(text))
            .unwrap(),
        TreeNodeChildren::Nodes(nodes) => {
            let child_nodes = nodes
                .iter()
                .map(|node| create_node(taffy, node, node_id_mapping, env))
                .collect::<Vec<NodeId>>();

            taffy
                .new_with_children(style.clone(), &child_nodes)
                .unwrap()
        }
    };

    node_id_mapping.insert(node_id, &node);
    return node_id;
}

fn node_style(node: &InputTreeNode, env: Env) -> Style {
    let mut default_style = Style::default();

    if let Some(style) = &node.style {
        default_style.size = node_size(style);

        default_style.border = Rect {
            top: LengthPercentage::Length(style.border.0 as f32),
            right: LengthPercentage::Length(style.border.1 as f32),
            bottom: LengthPercentage::Length(style.border.2 as f32),
            left: LengthPercentage::Length(style.border.3 as f32),
        };

        default_style.padding = Rect {
            top: LengthPercentage::Length(style.padding.0 as f32),
            right: LengthPercentage::Length(style.padding.1 as f32),
            bottom: LengthPercentage::Length(style.padding.2 as f32),
            left: LengthPercentage::Length(style.padding.3 as f32),
        };

        default_style.margin = Rect {
            top: LengthPercentageAuto::Length(style.margin.0 as f32),
            right: LengthPercentageAuto::Length(style.margin.1 as f32),
            bottom: LengthPercentageAuto::Length(style.margin.2 as f32),
            left: LengthPercentageAuto::Length(style.margin.3 as f32),
        };

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

        // Flex related attributes

        match style
            .flex_direction
            .to_term(env)
            .atom_to_string()
            .unwrap()
            .as_str()
        {
            "row" => default_style.flex_direction = FlexDirection::Row,
            "column" => default_style.flex_direction = FlexDirection::Column,
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
            default_style.grid_template_rows = template_rows
                .iter()
                .map(|v| match v {
                    InputLengthPercentage::Fixed(val) => TrackSizingFunction::Fixed(*val as f32),
                    InputLengthPercentage::Percent(val) => TrackSizingFunction::Percent(*val),
                })
                .collect();
        }

        if let Some(template_cols) = &style.grid_template_columns {
            default_style.grid_template_columns = template_cols
                .iter()
                .map(|v| match v {
                    InputLengthPercentage::Fixed(val) => TrackSizingFunction::Fixed(*val as f32),
                    InputLengthPercentage::Percent(val) => TrackSizingFunction::Percent(*val),
                })
                .collect();
        }

        if let Some(auto_rows) = &style.grid_auto_rows {
            default_style.grid_auto_rows = vec![match auto_rows {
                InputLengthPercentage::Fixed(val) => TrackSizingFunction::Fixed(*val as f32),
                InputLengthPercentage::Percent(val) => TrackSizingFunction::Percent(*val),
            }];
        }

        if let Some(auto_cols) = &style.grid_auto_columns {
            default_style.grid_auto_columns = vec![match auto_cols {
                InputLengthPercentage::Fixed(val) => TrackSizingFunction::Fixed(*val as f32),
                InputLengthPercentage::Percent(val) => TrackSizingFunction::Percent(*val),
            }];
        }

        if let Some((start, end)) = style.grid_row {
            default_style.grid_row = Line(GridPlacement::Line(start as i16))..Line(GridPlacement::Line(end as i16));
        }

        if let Some((start, end)) = style.grid_column {
            default_style.grid_column = Line(GridPlacement::Line(start as i16))..Line(GridPlacement::Line(end as i16));
        }
    }

    return default_style;
}

fn node_size(style: &InputTreeNodeStyle) -> Size<Dimension> {
    let width = style
        .width
        .clone()
        .map_or(Dimension::Auto, |value| match value {
            InputLengthPercentage::Fixed(v) => Dimension::Length(v as f32),
            InputLengthPercentage::Percent(v) => Dimension::Percent(v as f32),
        });

    let height = style
        .height
        .clone()
        .map_or(Dimension::Auto, |value| match value {
            InputLengthPercentage::Fixed(v) => Dimension::Length(v as f32),
            InputLengthPercentage::Percent(v) => Dimension::Percent(v as f32),
        });

    Size { width, height }
}

fn measure_text_sizes(
    text: &str,
    known_dimensions: Size<Option<f32>>,
    available_space: Size<AvailableSpace>,
    line_wrap: bool,
) -> Size<f32> {
    let text_sizes = |max_width: f32| -> Size<f32> {
        let mut lines_count = 0;
        let mut current_width = 0;
        let words: Vec<&str> = text.split_whitespace().collect();

        for word in words {
            // TODO: use graphemes instead
            let word_width = word.len();

            // Add 1 for space between words
            let width_with_word = current_width + word_width + 1;

            if current_width == 0 {
                current_width = word_width;
            } else if width_with_word as f32 <= max_width {
                current_width = width_with_word;
            } else {
                // Width is too long, move to next line
                lines_count += 1;
                current_width = word_width;
            }
        }

        if current_width > 0 {
            lines_count += 1;
        }

        Size {
            width: max_width,
            height: lines_count as f32,
        }
    };

    let single_line = Size {
        width: text.len() as f32,
        height: 1.0,
    };

    if !line_wrap {
        return single_line;
    }

    let result = match known_dimensions.width {
        Some(w) => text_sizes(w),
        None => match available_space.width {
            AvailableSpace::MinContent => {
                // For min content, each word is put in a separate line
                let words: Vec<&str> = text.split_whitespace().collect();

                let longest_word = words.iter().max_by_key(|v| v.len()).map_or(0, |v| v.len());

                Size {
                    width: longest_word as f32,
                    height: words.len() as f32,
                }
            }
            AvailableSpace::MaxContent => single_line,
            AvailableSpace::Definite(width) => text_sizes(width),
        },
    };

    return result;
}

fn collect_nodes(
    tree: &TaffyTree<NodeContext>,
    node_id: NodeId,
    node_id_mapping: &HashMap<NodeId, &InputTreeNode>,
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
                .map(|id| collect_nodes(tree, *id, node_id_mapping))
                .collect::<Vec<OutputTreeNode>>();
            TreeNodeChildren::Nodes(children)
        }
    };

    let root = OutputTreeNode {
        id: node_id_mapping.get(&node_id).map(|v| v.id).unwrap(),
        width: tree_layout.size.width as usize,
        height: tree_layout.size.height as usize,
        x: tree_layout.location.x as usize,
        y: tree_layout.location.y as usize,
        content_size: (
            tree_layout.content_size.width as usize,
            tree_layout.content_size.height as usize,
        ),
        border: OutputTreeNodeFourValues::from(tree_layout.border),
        padding: OutputTreeNodeFourValues::from(tree_layout.padding),
        margin: OutputTreeNodeFourValues::from(tree_layout.margin),
        children,
    };

    return root;
}

rustler::init!("Elixir.Orange.Layout.Binding", [layout]);
