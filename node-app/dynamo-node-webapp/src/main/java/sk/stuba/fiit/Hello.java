package sk.stuba.fiit;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;

@Path("hello")
public class Hello {

	@GET
	@Path("{name}")
	public String helloName(@PathParam("name") String name) {
		return "Hello "+name+" !";
	}
}
