# Changelog

## [1.0.0](https://github.com/Goose97/orange/compare/v0.5.0...v1.0.0) (2025-02-19)


### ⚠ BREAKING CHANGES

* update handle_event/4 callback
* handle_event now receives 4th argument

### Features

* add gap support for flex and grid ([e65ecf6](https://github.com/Goose97/orange/commit/e65ecf63b71ca2670d228d4368247e25e8e9d6ff))
* add Orange test framework ([bb42989](https://github.com/Goose97/orange/commit/bb429895e62dda3dea69a0a8e80c173cb1dd2eb3))
* add support for absolute position ([21179d5](https://github.com/Goose97/orange/commit/21179d5eceded0bf9109956bacfd52c7966a938a))
* background text with color and text modifiers ([fa0a029](https://github.com/Goose97/orange/commit/fa0a029fdea3c329b433b65da85cb209200b82cc))
* **component:** add tab bar ([6e0a4e2](https://github.com/Goose97/orange/commit/6e0a4e22c102e9c65afe7a9861807285a5d3b466))
* don't crash if component_id is not found ([243d182](https://github.com/Goose97/orange/commit/243d182e153acab32ef300c190381aa67dd7ac4a))
* fixed position doesn't have to specify all offsets ([0a444ea](https://github.com/Goose97/orange/commit/0a444ea2a1a03ead6562b2d24d67f16a2acd6c7b))
* handle multi code point chars ([e9b76f1](https://github.com/Goose97/orange/commit/e9b76f1721e70f1a5f73b201c526491c4ea62e19))
* handle_event now receives 4th argument ([fb82792](https://github.com/Goose97/orange/commit/fb827922417e7ddf784ff9d8c8758e1895080165))
* implement API to get layout information ([1721b5f](https://github.com/Goose97/orange/commit/1721b5f13a22049a544153dcd3216dfeef4ec86c))
* move rounding logic to Elixir app ([fd291c2](https://github.com/Goose97/orange/commit/fd291c2989939b84080454faeb88d6614eb29099))
* multi strings title ([f8019e0](https://github.com/Goose97/orange/commit/f8019e0d0f92385ad5332d499849f3f0ea9c2989))
* support background_text attribute ([dcdf58f](https://github.com/Goose97/orange/commit/dcdf58fdee7bcb21950ba8948e3c9b626b2f0cbc))
* support more border styles ([8a1bf00](https://github.com/Goose97/orange/commit/8a1bf00b32c3200bfd002f531d2375de22b29333))
* **test:** add :function type event ([829e27c](https://github.com/Goose97/orange/commit/829e27cc07ed6489bd62fb03301ca1bc92f1786d))
* **test:** add more test utilities ([56830c8](https://github.com/Goose97/orange/commit/56830c85ca54b9b799fe46a1f74aa771a75442c6))
* **test:** range assertions ([b424bb2](https://github.com/Goose97/orange/commit/b424bb2c04e9afc34fdd2e77749a1ff016bb5915))
* update handle_event/4 callback ([fb944db](https://github.com/Goose97/orange/commit/fb944db9b3916a271db6e4f6956e25f00b2402df))


### Bug Fixes

* absolute children doesn't have styles ([ab9f646](https://github.com/Goose97/orange/commit/ab9f6462334b548987baa3001fbe152da7c18ffd))
* add deadline to batch update ([f4eddf8](https://github.com/Goose97/orange/commit/f4eddf8a8a2db2e6e960c5cf1d2d3fefcd32ba5b))
* app should not crash on EXIT message ([5754a90](https://github.com/Goose97/orange/commit/5754a904619ca9f33b7596e9e64ae82bb9b6bd25))
* broken tests ([67a1b73](https://github.com/Goose97/orange/commit/67a1b73b1fd89eea3700c68983d3a56b6415964d))
* crash when children is nil ([48be708](https://github.com/Goose97/orange/commit/48be708e61faad7b9be7186a5eb0fa011a172ef3))
* don't crash if component is not found ([cb6d4d7](https://github.com/Goose97/orange/commit/cb6d4d71841bf98f2b2556d53a03a28f0d89a913))
* fixed and absolute children doesn't inherit style from parent ([6962319](https://github.com/Goose97/orange/commit/6962319b9625891c32f79d62cddd9454ecfd9bb1))
* incorrectly render text with leading or trailing whitespaces ([7f03c59](https://github.com/Goose97/orange/commit/7f03c59f27c1d22c77758e859d7d905059ae1632))
* single text rect doesn't apply style properly ([9cf60be](https://github.com/Goose97/orange/commit/9cf60beb0e2c9825e8fe3942c806b6c2a2c37a3c))
* single word text with leading whitespaces render incorrectly ([45be8b1](https://github.com/Goose97/orange/commit/45be8b1fa22958470246c09f5da62d4383f62a27))
