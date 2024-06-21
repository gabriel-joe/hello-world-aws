package com.training.aws.api.response;

public class HelloWorldAwsResponse {
    private String message;

    public HelloWorldAwsResponse(String message) {
        this.message = message;
    }

    public String getMessage() {
        return message;
    }
}
