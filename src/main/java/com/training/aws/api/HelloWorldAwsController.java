package com.training.aws.api;

import java.text.ParseException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.training.aws.api.request.HelloWorldAwsRequest;
import com.training.aws.api.response.HelloWorldAwsResponse;
import com.training.aws.service.HelloWorldAwsService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/hello")
public class HelloWorldAwsController {

    private final HelloWorldAwsService helloWorldAwsService;

    public HelloWorldAwsController(HelloWorldAwsService helloWorldAwsService) {
        this.helloWorldAwsService = helloWorldAwsService;
    }

    @PutMapping("/{username}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public ResponseEntity<String> updateBirthday(@PathVariable String username, @Valid @RequestBody HelloWorldAwsRequest request) {
        try {
            helloWorldAwsService.saveOrUpdateUser(username, request.getDateOfBirth());
            return ResponseEntity.ok().build();
        } catch (ParseException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(e.getMessage());
        }
    }

    @GetMapping("/{username}")
    public HelloWorldAwsResponse getBirthdayGreeting(@PathVariable String username) {
        try {
            return new HelloWorldAwsResponse(helloWorldAwsService.getHelloBirthdayMessage(username));
        } catch (Exception e) {
            return new HelloWorldAwsResponse(e.getMessage());
        }
    }

}