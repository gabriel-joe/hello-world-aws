package com.training.aws.api.request;

import org.springframework.validation.annotation.Validated;

import jakarta.validation.constraints.Pattern;

@Validated
public class HelloWorldAwsRequest {

    @Pattern(regexp = "^\\d{4}-\\d{2}-\\d{2}$", message = "Invalid date format. Please use YYYY-MM-DD.")
    private String dateOfBirth;

    public String getDateOfBirth(){
        return dateOfBirth;
    }

}
