package sk.stuba.fiit;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;

import org.apache.log4j.Logger;

@Path("hello")
public class Hello {

	private static org.apache.log4j.Logger log = Logger.getLogger(Hello.class);

	@GET
	@Path("{name}")
	public String helloName(@PathParam("name") String name) {
		log.info("helloName called with name : "+name);
		return "Hello " + name + " !";
	}
}
