package com.training.aws.model;

import java.time.LocalDate;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class HelloWorldAwsModel {
    private String username;
    private LocalDate dateOfBirth;

    public HelloWorldAwsModel() {
    }

    public HelloWorldAwsModel(String username, LocalDate dateOfBirth) {
        this.username = username;
        this.dateOfBirth = dateOfBirth;
    }

    public String getUsername(){
        return username;
    }

    public LocalDate getDateOfBirth(){
        return dateOfBirth; 
    }
}
