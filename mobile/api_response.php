<?php

class ApiResponse {
    // Success response with data
    public static function success($message = 'Operation successful', $data = null) {
        return [
            'success' => true,
            'message' => $message,
            'data' => $data,
            'timestamp' => date('Y-m-d H:i:s')
        ];
    }
    
    // Error response
    public static function error($message = 'Operation failed', $errors = null, $code = 400) {
        http_response_code($code);
        return [
            'success' => false,
            'message' => $message,
            'errors' => $errors,
            'timestamp' => date('Y-m-d H:i:s')
        ];
    }
    
    // Send JSON response
    public static function send($response) {
        echo json_encode($response);
        exit();
    }
}
?>
