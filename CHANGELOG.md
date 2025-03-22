# Changelog

## [1.0.0](https://github.com/Goose97/orange/compare/v0.5.0...v1.0.0) (2025-03-22)


### ⚠ BREAKING CHANGES

* remove VerticalScrollableRect component
* we don't support title as list anymore. Also, attributes for title like color or text_modifiers have been removed in favor of styling with rect element.
* update handle_event/4 callback
* handle_event now receives 4th argument

### Features

* add before_update/2 callback ([a8ccb34](https://github.com/Goose97/orange/commit/a8ccb341189dedae732feb087ebfcd84f1dad0cb))
* add footer support for rect ([99bfe77](https://github.com/Goose97/orange/commit/99bfe77beff84c27ccb1d96ede7a54675adfb25f))
* add gap support for flex and grid ([e65ecf6](https://github.com/Goose97/orange/commit/e65ecf63b71ca2670d228d4368247e25e8e9d6ff))
* add grid_auto_rows and grid_auto_columns support ([1501879](https://github.com/Goose97/orange/commit/150187994cf36a77c2d17e07d14d836a7aaee112))
* add min/max width and height ([15d4691](https://github.com/Goose97/orange/commit/15d469195aac5403552f49bf4c64dfd4b3a28409))
* add Orange test framework ([bb42989](https://github.com/Goose97/orange/commit/bb429895e62dda3dea69a0a8e80c173cb1dd2eb3))
* add scroll_bar style attribute ([d66ce30](https://github.com/Goose97/orange/commit/d66ce30fde407af3a25b7e09f2114ac68dcc81b7))
* add support for absolute position ([21179d5](https://github.com/Goose97/orange/commit/21179d5eceded0bf9109956bacfd52c7966a938a))
* add update callback to before_update/3 ([ab79991](https://github.com/Goose97/orange/commit/ab799918b3c40428add9b8343b13e743db52ef2c))
* background text with color and text modifiers ([fa0a029](https://github.com/Goose97/orange/commit/fa0a029fdea3c329b433b65da85cb209200b82cc))
* **component:** add tab bar ([6e0a4e2](https://github.com/Goose97/orange/commit/6e0a4e22c102e9c65afe7a9861807285a5d3b466))
* don't crash if component_id is not found ([243d182](https://github.com/Goose97/orange/commit/243d182e153acab32ef300c190381aa67dd7ac4a))
* fixed position doesn't have to specify all offsets ([0a444ea](https://github.com/Goose97/orange/commit/0a444ea2a1a03ead6562b2d24d67f16a2acd6c7b))
* handle multi code point chars ([e9b76f1](https://github.com/Goose97/orange/commit/e9b76f1721e70f1a5f73b201c526491c4ea62e19))
* handle_event now receives 4th argument ([fb82792](https://github.com/Goose97/orange/commit/fb827922417e7ddf784ff9d8c8758e1895080165))
* implement API to get layout information ([1721b5f](https://github.com/Goose97/orange/commit/1721b5f13a22049a544153dcd3216dfeef4ec86c))
* **modal:** style from attrs has higher precedence ([85d6ee9](https://github.com/Goose97/orange/commit/85d6ee906dc8156f1e0c44c248e31ddea64b9c58))
* move rounding logic to Elixir app ([fd291c2](https://github.com/Goose97/orange/commit/fd291c2989939b84080454faeb88d6614eb29099))
* multi strings title ([f8019e0](https://github.com/Goose97/orange/commit/f8019e0d0f92385ad5332d499849f3f0ea9c2989))
* raise error if encounter invalid children ([780ef78](https://github.com/Goose97/orange/commit/780ef782ea73a2eec180c543670f5648eb53d339))
* remove VerticalScrollableRect component ([35efe32](https://github.com/Goose97/orange/commit/35efe328bb69186bd06024920147fcd41594c55c))
* render scrollbar when scroll_x or scroll_y is specified ([9e50eff](https://github.com/Goose97/orange/commit/9e50eff80d6e61befebe138a5f956090e12431d1))
* rework test buffers capture interface ([b4c2367](https://github.com/Goose97/orange/commit/b4c23671b81afaae781bab0cd13fc55852d78c66))
* scroll bar color should match border color ([c6abb19](https://github.com/Goose97/orange/commit/c6abb19d995f92a89bc9a0446a9ca78365e6138b))
* support background_text attribute ([dcdf58f](https://github.com/Goose97/orange/commit/dcdf58fdee7bcb21950ba8948e3c9b626b2f0cbc))
* support custom char for empty cell for Buffer.to_string/2 ([530d863](https://github.com/Goose97/orange/commit/530d8633206725d68b1dc2caee4ce8c34275004a))
* support more border styles ([8a1bf00](https://github.com/Goose97/orange/commit/8a1bf00b32c3200bfd002f531d2375de22b29333))
* support title alignment ([73455d2](https://github.com/Goose97/orange/commit/73455d2d5f15fd54e8d29bac02200be1006ad5ae))
* support title as a rect element ([505c141](https://github.com/Goose97/orange/commit/505c141acedcd107a49f86997d2055abfea528cf))
* **test:** add :function type event ([829e27c](https://github.com/Goose97/orange/commit/829e27cc07ed6489bd62fb03301ca1bc92f1786d))
* **test:** add more test utilities ([56830c8](https://github.com/Goose97/orange/commit/56830c85ca54b9b799fe46a1f74aa771a75442c6))
* **test:** range assertions ([b424bb2](https://github.com/Goose97/orange/commit/b424bb2c04e9afc34fdd2e77749a1ff016bb5915))
* update handle_event/4 callback ([fb944db](https://github.com/Goose97/orange/commit/fb944db9b3916a271db6e4f6956e25f00b2402df))


### Bug Fixes

* absolute children doesn't have styles ([ab9f646](https://github.com/Goose97/orange/commit/ab9f6462334b548987baa3001fbe152da7c18ffd))
* absolute elements inside scrollable elements ([b9e62f4](https://github.com/Goose97/orange/commit/b9e62f4d39e2ef9acbae99eda082eac521e9e8f2))
* add deadline to batch update ([f4eddf8](https://github.com/Goose97/orange/commit/f4eddf8a8a2db2e6e960c5cf1d2d3fefcd32ba5b))
* adjust rounding algorithm ([9823a92](https://github.com/Goose97/orange/commit/9823a9244bafc78f694befb755afdd5eb2fde72e))
* app should not crash on EXIT message ([5754a90](https://github.com/Goose97/orange/commit/5754a904619ca9f33b7596e9e64ae82bb9b6bd25))
* broken tests ([c379ae7](https://github.com/Goose97/orange/commit/c379ae73f6b5f78bb836f6b3a53fa9730d501c5b))
* broken tests ([67a1b73](https://github.com/Goose97/orange/commit/67a1b73b1fd89eea3700c68983d3a56b6415964d))
* crash on out of bounds background color set ([bc150e3](https://github.com/Goose97/orange/commit/bc150e31fadc76e200bdb1f260752464b0e12bdd))
* crash when children is nil ([48be708](https://github.com/Goose97/orange/commit/48be708e61faad7b9be7186a5eb0fa011a172ef3))
* crash when children list contains nil ([2a0d651](https://github.com/Goose97/orange/commit/2a0d6514f88d760c96cfa43e3d75b1375b2a0c4d))
* crash when clear out of bound area ([a80a328](https://github.com/Goose97/orange/commit/a80a3280aaaf92fcc299f94fe34964a2611046e1))
* crash when render out of bound content ([a251ad8](https://github.com/Goose97/orange/commit/a251ad88c6a4d1bc86c339cc8016534139060e7d))
* crash when scrollable elements have 0 width or height ([31bf10a](https://github.com/Goose97/orange/commit/31bf10a870bb21ecc2ad228f01e5bbf08d1f95a6))
* don't crash if component is not found ([cb6d4d7](https://github.com/Goose97/orange/commit/cb6d4d71841bf98f2b2556d53a03a28f0d89a913))
* don't crash on out of bounds write ([e52551c](https://github.com/Goose97/orange/commit/e52551c37de1a3516e5039775370d0f903b8a644))
* fixed and absolute children doesn't inherit style from parent ([6962319](https://github.com/Goose97/orange/commit/6962319b9625891c32f79d62cddd9454ecfd9bb1))
* handle zero width/height elements ([184cc2a](https://github.com/Goose97/orange/commit/184cc2a4e43b04e88af687893ce940d80ca7dadb))
* incorrectly render text with leading or trailing whitespaces ([7f03c59](https://github.com/Goose97/orange/commit/7f03c59f27c1d22c77758e859d7d905059ae1632))
* missing elements within fixed nodes in output tree lookup ([47b3194](https://github.com/Goose97/orange/commit/47b3194c4ba4b0c04a03d7961d93ad946686930b))
* missing unmount components ([cb860a0](https://github.com/Goose97/orange/commit/cb860a0738ce50cb6756fba9738b0e679d085ebe))
* scroll crash on rect ([b2e86c3](https://github.com/Goose97/orange/commit/b2e86c3418904e8f06d3c1343dbd1af52276fd14))
* set background cell color crash on unsize buffer ([193b288](https://github.com/Goose97/orange/commit/193b288f0a7fc006913005c806d3b766ab687756))
* single text rect doesn't apply style properly ([9cf60be](https://github.com/Goose97/orange/commit/9cf60beb0e2c9825e8fe3942c806b6c2a2c37a3c))
* single word text with leading whitespaces render incorrectly ([45be8b1](https://github.com/Goose97/orange/commit/45be8b1fa22958470246c09f5da62d4383f62a27))
