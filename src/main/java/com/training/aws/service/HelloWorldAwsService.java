package com.training.aws.service;

import java.text.ParseException;
import java.time.LocalDate;
import java.time.Period;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.springframework.stereotype.Service;

import com.training.aws.model.UserEntity;
import com.training.aws.repository.HelloWorldAwsRepository;

@Service
public class HelloWorldAwsService {

    private HelloWorldAwsRepository userRepository;
    
    public HelloWorldAwsService(HelloWorldAwsRepository userRepository) {
        this.userRepository = userRepository;
    }
    public void saveOrUpdateUser(String username, String dateOfBirth) throws Exception {
        validateUsername(username);
        validateDateOfBirth(dateOfBirth);
        userRepository.save(new UserEntity(username, LocalDate.parse(dateOfBirth)));
    }

    
    public String getHelloBirthdayMessage(String username) throws Exception {
        validateUsername(username);
        Optional<UserEntity> user = userRepository.findById(username);
        LocalDate today = LocalDate.now();
        long daysToBirthday = Period.between(today, user.get().getDateOfBirth()).getDays();
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