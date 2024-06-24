package com.training.aws.hello_world;

import static org.junit.jupiter.api.Assertions.assertEquals;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class HelloWorldAwsApplicationTests {
	
	private String URL_TO_SEND = "/hello/%s";

	@Test
	void contextLoads() {
	}

	@LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

	private HttpHeaders headers;

	private HttpHeaders loadHeaders() {
		if(headers == null) {
			headers = new HttpHeaders();
			headers.setContentType(MediaType.APPLICATION_JSON);
		}
		return headers;
	}

    @Test
    public void testSaveUsernameAndBirthday() throws Exception {
        String username = "johndoe";
        String birthday = "1990-01-01";

        // Prepare the request body
        String requestBody = "{\"dateOfBirth\": \"" + birthday + "\"}";
        // Send the PUT request
        ResponseEntity<String> response = restTemplate.exchange(String.format(URL_TO_SEND, username), HttpMethod.PUT, new HttpEntity<>(requestBody, loadHeaders()), String.class);

        // Verify response status and body
        assertEquals(HttpStatus.NO_CONTENT, response.getStatusCode());
    }

	@Test
    public void testSaveUsernameAndBirthday_EmptyBody() throws Exception {
        // Send PUT request with empty body
        ResponseEntity<String> response = restTemplate.exchange(String.format(URL_TO_SEND, "user"), HttpMethod.PUT, new HttpEntity<>(null, null), String.class);

        // Verify response status for bad request
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
    }

    @Test
    public void testSaveUsernameAndBirthday_InvalidBirthdayFormat() throws Exception {
        String username = "janedoe";
        String birthday = "invalid-birthday-format"; // Invalid format

        String requestBody = "{\"dateOfBirth\": \"" + birthday + "\"}";
		ResponseEntity<String> response = restTemplate.exchange(String.format(URL_TO_SEND, username), HttpMethod.PUT, new HttpEntity<>(requestBody, loadHeaders()), String.class);

    	assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
    }

    @Test
    public void testDaysToNextBirthday_NoUser() throws Exception {
        // Send the GET request
        ResponseEntity<String> response = restTemplate.getForEntity(String.format(URL_TO_SEND, ""), String.class);
        // Verify response status for not found
        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
    }

    @Test
    public void testDaysToNextBirthday_AfterSave() throws Exception {
        // Send the GET request
		String username = "johndoe";
        testSaveUsernameAndBirthday();
		ResponseEntity<String> response = restTemplate.getForEntity(String.format(URL_TO_SEND, username), String.class);
		
        // Verify response status and body
        assertEquals(HttpStatus.OK, response.getStatusCode());

        String messageResponse = response.getBody();

        // Calculate expected days based on today's date and birthday
        int currentYear = LocalDate.now().getYear();
        LocalDate birthdayDate = LocalDate.parse("1990-01-01");
		if(birthdayDate.withYear(currentYear).isBefore(LocalDate.now())){
			currentYear += 1;
		}
        long daysBetween = ChronoUnit.DAYS.between(LocalDate.now(), birthdayDate.withYear(currentYear));
		String expectedResponseBody = String.format("{\"message\":\"Hello, %s! Your birthday is in %s day(s).\"}", username, daysBetween);
        // Assert that the returned days match the expected days
        assertEquals(expectedResponseBody, messageResponse);
    }
}
