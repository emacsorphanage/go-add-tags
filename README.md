# go-add-tags.el [![travis badge][travis-badge]][travis-link]

Add field tags for struct fields. This package is inspired by `GoAddTags` of [vim-go](https://github.com/fatih/vim-go).

## Interfaces

##### `go-add-tags`

Insert tag at current line. You can input multiple tags at once by comma, like `json,yaml`.
If region is enabled, then tags are inserted in lines in region. And `current-prefix-key` is specified,
then you can choose field convertion function.

## Customization

##### `go-add-tags-conversion`(Default: 'snake-case)

How to convert filed in tag from field name.

- `snake-case`
- `lower-camel-case`
- `upper-camel-case`
- `original`

[travis-badge]: https://travis-ci.org/syohex/emacs-go-add-tags.svg
[travis-link]: https://travis-ci.org/syohex/emacs-go-add-tags
