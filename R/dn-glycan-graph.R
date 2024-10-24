# New Dual-Node Glycan Graph
new_dn_glycan_graph <- function(graph) {
  stopifnot(igraph::is_igraph(graph))
  structure(graph, class = c("dn_glycan_graph", "glycan_graph", "igraph"))
}


validate_dn_glycan_graph <- function(glycan) {
  stopifnot(inherits(glycan, "dn_glycan_graph"))
  # Check if it is a directed graph
  if (!is_directed_graph(glycan)) {
    rlang::abort("Glycan graph must be directed.")
  }
  # Check if it is an out tree
  if (!is_out_tree(glycan)) {
    rlang::abort("Glycan graph must be an out tree.")
  }
  # Check if graph has the right vertex attributes
  if (!has_vertex_attrs(glycan, c("type", "mono", "linkage"))) {
    rlang::abort("Glycan graph must have vertex attributes 'type', 'mono' and 'linkage'.")
  }
  # Check if no NA in "type" attribute
  if (any(is.na(igraph::vertex_attr(glycan, "type")))) {
    rlang::abort("Glycan graph must have no NA in 'type' attribute.")
  }
  # Check if only "mono" and "linkage" are in "type" attribute
  if (!all(igraph::V(glycan)$type %in% c("mono", "linkage"))) {
    rlang::abort("The 'type' of a node could either be 'mono' or 'linkage'.")
  }
  # Check if "mono" and "linkage" nodes are alternating
  if (!check_alternating(glycan)) {
    rlang::abort("The 'mono' and 'linkage' nodes must be alternating.")
  }
  # Check if no NA in "mono" attribute for "mono" nodes
  mono_names <- get_vertex_attr(glycan, "mono", "mono")
  if (any(is.na(mono_names))) {
    rlang::abort("Mono nodes must have no NA in 'mono' attribute.")
  }
  # Check if all monosaccharides are known
  if (!all(is_known_mono(mono_names))) {
    unknown_monos <- mono_names[!is_known_mono(mono_names)]
    msg <- glue::glue("Unknown monosaccharide: {stringr::str_c(unknown_monos, collapse = ', ')}")
    rlang::abort(msg, monos = unknown_monos)
  }
  # Check if mixed use of generic and concrete monosaccharides
  if (mix_generic_concrete(mono_names)) {
    rlang::abort("Mono nodes must not mix generic and concrete monosaccharides.")
  }
  # Check if all linkages are valid
  linkages <- get_vertex_attr(glycan, "linkage", "linkage")
  linkages <- linkages[!is.na(linkages)]
  if (!all(valid_linkages(linkages))) {
    invalid_linkages <- unique(linkages[!valid_linkages(linkages)])
    msg <- glue::glue("Invalid linkage: {stringr::str_c(invalid_linkages, collapse = ', ')}")
    rlang::abort(msg, linkages = invalid_linkages)
  }
  # Check if no exposed "linkage" nodes
  linkage_nodes <- which(igraph::V(glycan)$type == "linkage")
  out_degrees <- igraph::degree(glycan, v = linkage_nodes, mode = "out")
  if (any(out_degrees == 0)) {
    rlang::abort("Linkage nodes must not have an out-degree of zero (no exposed linkages)")
  }

  glycan
}


check_alternating <- function(graph) {
  edge_list <- igraph::as_edgelist(graph, names = FALSE)
  types <- igraph::V(graph)$type
  u <- edge_list[,1]
  v <- edge_list[,2]
  all(types[u] != types[v])
}


get_vertex_attr <- function(graph, type, attr) {
  igraph::vertex_attr(graph, attr)[igraph::vertex_attr(graph, "type") == type]
}
