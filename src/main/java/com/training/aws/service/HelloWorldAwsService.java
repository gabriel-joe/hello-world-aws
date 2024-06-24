package com.training.aws.service;

import java.text.ParseException;
import java.time.LocalDate;
import java.time.Period;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.naming.NameNotFoundException;

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
        if(user.isPresent()) {
            LocalDate today = LocalDate.now();
            int birthYear = today.getYear();
            if(user.get().getDateOfBirth().isBefore(today)) {
                birthYear += 1;
            }
            long daysToBirthday = ChronoUnit.DAYS.between(LocalDate.now(), user.get().getDateOfBirth().withYear(birthYear));
            if (daysToBirthday == 0) {
                return "Hello, " + username + "! Happy birthday!";
            } else {
                return "Hello, " + username + "! Your birthday is in " + daysToBirthday + " day(s).";
            }
        } else {
            throw new NameNotFoundException("User not found!");
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