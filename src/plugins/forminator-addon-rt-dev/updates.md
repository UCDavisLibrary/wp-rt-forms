# update notes for new forminator api

## Addon Class

Change forminator classes
 - `Forminator_Addon_Abstract` to `Forminator_Integration`
 - `Forminator_Addon_Loader` to `Forminator_Integration_Loader`

Static instance
In addon class,
- update `private static $_instance = null;` to `protected static $instance = null;`
- remove `get_instance` method
- remove `$_form_settings` property
- remove `$_form_hooks` property


Assets directory in addon class:
- add `addon_path` method - needs to be defined as string
- add `assets_path` method - needs to be defined as string
- remove `$this->_icon ` and `$this->_image` from constructor
- remove `_icon_x2`, `_full_path`, and `_image_x2` property declarations
- rename image to `icon.png` and `image.png`
  
```php
  public function addon_path() : string  {
    return forminator_addon_rt_url();
  }

  public function assets_path() : string {
    return forminator_addon_rt_assets_url();
  }
```

Update to form connection
- remove `is_form_connected` entirely

## form settings class
class updates
- rename main class to format `'Forminator_' . ucfirst( $addon_slug ) . '_' . 'Form_Settings';`
- `Forminator_Addon_Form_Settings_Abstract` to `Forminator_Integration_Form_Settings`
- `Forminator_Addon_Abstract::get_button_markup` to `Forminator_Integration::get_button_markup`
- `Forminator_Addon_Abstract::get_template` to `Forminator_Integration::get_template`

method updates
- remove _construct
- `form_settings_wizards` becomes `module_settings_wizards`
- `get_form_settings_values` becomes `get_settings_values` 
- `save_form_settings_values` becomes `save_module_settings_values`

## Hooks class
class updates
- `Forminator_Addon_Form_Hooks_Abstract` becomes `Forminator_Integration_Form_Hooks`
- update constructor to `__construct(Forminator_Integration $addon, int $module_id)`, and change `form_id` to `module_id`
- update all references to `this->form_id` to `$this->module_id`
- rename main class name to format `'Forminator_' . ucfirst( $addon_slug ) . '_' . 'Form_Hooks';`

method updates
- `public function on_export_render_title_row(){ ` becomes `public function on_export_render_title_row() : array {`
- `on_form_submit` becomes `on_module_submit`
- `$this->form_settings_instance` becomes `$this->settings_instance`
- `$this->_submit_form_error_message ` becomes `$this->submit_error_message`
- `$this->custom_form` becomes `$this->module` 

