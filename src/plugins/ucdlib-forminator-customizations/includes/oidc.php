<?php

/**
 * @description This class contains customizations for authorization and authentication
 * Most auth work is handled by the openid-connect-generic plugin, but we need some customizations
 */
class UcdlibAuth {
  public function __construct(){
    $this->oidcIsActivated = in_array('openid-connect-generic/openid-connect-generic.php', apply_filters('active_plugins', get_option('active_plugins')));

    if ( $this->oidcIsActivated ) {
      add_action('after_setup_theme', [$this, 'hideAdminBar']);
      add_action( 'openid-connect-generic-update-user-using-current-claim', [$this, 'setAdvancedRole'], 10, 2 );
      add_action( 'openid-connect-generic-user-create', [$this, 'setAdvancedRole'], 10, 2 );
    }

  }

  /**
   * @description Hide the floating admin bar on front-end pages for "subscribers"
   * We force authentication for all pages on this site, and most users are assigned the subscriber role.
   * Since they can't edit the site, we hide the admin bar for them
   */
  public function hideAdminBar(){
    $user = wp_get_current_user();
    if ( !$user ) return;
    $allowedRoles = array( 'editor', 'administrator', 'author' );
    if (!array_intersect( $allowedRoles, $user->roles ) && !is_admin()) {
      show_admin_bar(false);
    }
  }

  /**
   * @description Set the wordpress user role beyond default subscriber,
   * if the user has a corresponding claim in access token from identity provider.
   */
  public function setAdvancedRole($user, $userClaim){
    $accessTokenEncoded = get_user_meta( $user->ID, 'openid-connect-generic-last-token-response', true );
    if ( !$accessTokenEncoded ) return;
    try {
      $parts = explode( '.', $accessTokenEncoded['access_token'] );
      if ( count( $parts ) != 3 ) return;
      $accessToken = json_decode(
        base64_decode(
          str_replace(
            array( '-', '_' ),
            array( '+', '/' ),
            $parts[1]
          )
        ),
        true
      );
    } catch (\Throwable $th) {
      return;
    }
    if ( !$accessToken ) return;
    set_transient( 'steve', $accessToken );

    $wpRole = '';

    // check realm roles
    if ( isset( $accessToken['realm_access']['roles'] ) ) {
      if ( in_array('admin-access',  $accessToken['realm_access']['roles']) ){
        $wpRole = 'administrator';
      }
    }

    // check client roles
    //$client = OIDC_CLIENT_ID

    if ( $wpRole ) {
      $user->set_role( $wpRole );
    }

  }
}
