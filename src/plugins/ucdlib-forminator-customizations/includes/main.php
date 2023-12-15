<?php
require_once( __DIR__ . '/create-ticket.php' );
require_once( __DIR__ . '/oidc.php' );
require_once( __DIR__ . '/styles.php' );

class UcdlibForminator {
  public $auth;
  public function __construct(){
    $this->auth = new UcdlibAuth();
    new UcdlibForminatorStyles();
    new UcdlibCreateTicket();
  }
}
