<?php
/**
 * Plugin Name: UC Davis Library Customizations
 * Description: Our customizations go here.
 * Author: UC Davis Library Online Strategy
 */

function ucdlib_forminator_url() {
	return trailingslashit( plugin_dir_url( __FILE__ ) );
}

function ucdlib_forminator_assets_url() {
	return trailingslashit( ucdlib_forminator_url() . 'assets' );
}

require_once( __DIR__ . '/includes/main.php' );
new UcdlibForminator();
