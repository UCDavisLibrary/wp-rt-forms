<?php
require_once( __DIR__ . '/oidc.php' );
require_once( __DIR__ . '/styles.php' );

class UcdlibForminator {
  public function __construct(){
    $this->auth = new UcdlibAuth();
    new UcdlibForminatorStyles();
  }
}
