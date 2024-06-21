package com.training.aws.service;

import java.text.ParseException;
import java.time.LocalDate;
import java.time.Period;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.springframework.stereotype.Service;

import com.training.aws.model.HelloWorldAwsModel;

@Service
public class HelloWorldAwsService {

private static final InMemoryUserRepository userRepository = new InMemoryUserRepository();

    
    public void saveOrUpdateUser(String username, String dateOfBirth) throws Exception {
        validateUsername(username);
        validateDateOfBirth(dateOfBirth);
        userRepository.save(new HelloWorldAwsModel(username, LocalDate.parse(dateOfBirth)));
    }

    
    public String getHelloBirthdayMessage(String username) throws Exception {
        validateUsername(username);
        HelloWorldAwsModel user = userRepository.getUser(username);
        LocalDate today = LocalDate.now();
        long daysToBirthday = Period.between(today, user.getDateOfBirth()).getDays();
        if (daysToBirthday == 0) {
            return "Hello, " + username + "! Happy birthday!";
        } else {
            return "Hello, " + username + "! Your birthday is in " + daysToBirthday + " day(s)";
        }
    }

    private void validateUsername(String username) throws Exception {
        Pattern pattern = Pattern.compile("^[a-zA-Z]+$");
        Matcher matcher = pattern.matcher(username);
        if (!matcher.matches()) {
            throw new Exception("Username must contain only letters");
        }
    }

    private void validateDateOfBirth(String dateOfBirth) throws ParseException {
        LocalDate dob = LocalDate.parse(dateOfBirth);
        if (dob.isAfter(LocalDate.now())) {
            throw new ParseException("Date of Birth cannot be in the future", 0);
        }
    }
}

// This is a temporary in-memory user repository for demonstration purposes.
// You'll need to implement a real data access layer for production.
class InMemoryUserRepository {
    private Map<String, HelloWorldAwsModel> users = new HashMap<>();

    public void save(HelloWorldAwsModel user) {
        users.put(user.getUsername(), user);
    }

    public HelloWorldAwsModel getUser(String username) {
        return users.get(username);
    }

}