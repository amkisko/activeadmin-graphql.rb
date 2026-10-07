## Dependency

activeadmin-graphql (this gem). List queries already expose paginated Ransack q, order, and first or last.

## Symptom

The gem has no Formtastic or Stimulus association picker that queries those lists as the person types. Hosts that need searchable associations either embed full catalogs in select or datalist, or keep a local combobox.

## Evidence

Schema and docs describe list fields with the same filter contract as the JSON index. There is no shipped input or controller that posts first and q, keeps a label plus hidden id, and replaces a bounded page on further typing.

## Suggested fix

When a second host needs the same control, or when packaging is requested, ship a Formtastic input and Stimulus controller that take GraphQL field name, node selection fields, search key, order, first, and optional extra q. Do not bake product model names into the gem. Keep host field maps and labels in the host. Until then, leave pickers host-local. Do not publish a third gem only for this picker.

## Next

Open an issue or pull request for the generic picker when packaging is requested. Index filter sidebars and multi-select include or exclude catalogs are out of scope for that first slice. Loading and error states, multi-select, and filter-sidebar wiring remain open after a first single-select page.

## Source

- docs/graphql-api.md list query contract
