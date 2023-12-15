<?php

/**
 * Customizations to RT ticket creation
 */
class UcdlibCreateTicket {

  public function __construct(){
    add_filter( 'forminator_addon_rt_ticket_data', [$this, 'addDepartment'], 10, 3 );
  }

  /**
   * Query the personnel API for the user's department
   * Add department to ticket custom fields
   */
  public function addDepartment( $ticketData, $form, $submission ){

    $apiUrl = getenv('UCDLIB_PERSONNEL_API_URL');
    $apiUser = getenv('UCDLIB_PERSONNEL_API_USER');
    $apiKey = getenv('UCDLIB_PERSONNEL_API_KEY');
    $requesterEmail = $ticketData['Requestor'];
    if ( !$apiUrl || !$apiUser || !$apiKey || !$requesterEmail ) return $ticketData;

    try {
      $authHeader = 'Basic ' . base64_encode( $apiUser . ':' . $apiKey );
      $url = trailingslashit( $apiUrl ) . 'groups/member/' . $requesterEmail . '?id-type=email&part-of-org=true';
      $response = wp_remote_get( $url, [
        'headers' => [
          'Authorization' => $authHeader
        ]
      ] );
      if ( is_wp_error( $response ) ) return $ticketData;
      $body = wp_remote_retrieve_body( $response );
      $data = json_decode( $body, true );
      if ( !$data ) return $ticketData;
      if ( empty( $data[0]['rt_name'] ) ) return $ticketData;

      if ( !isset( $ticketData['CustomFields']) ) $ticketData['CustomFields'] = [];
      $ticketData['CustomFields']['1'] = $data[0]['rt_name'];

    } catch (\Throwable $th) {
      // fail silently
    }
    return $ticketData;
  }

}
