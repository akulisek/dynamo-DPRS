package sk.stuba.fiit;

import java.io.IOException;
import java.net.InetAddress;
import java.util.List;

import org.apache.log4j.Logger;

import com.ecwid.consul.v1.ConsulClient;
import com.ecwid.consul.v1.QueryParams;
import com.ecwid.consul.v1.Response;
import com.ecwid.consul.v1.catalog.model.CatalogService;

public class CommThread extends Thread {
	private static org.apache.log4j.Logger log = Logger.getLogger(CommThread.class);
	private static String serviceName = "java_image-8080";
	
	public void run() {
		try {
			sleep(5000);
			ConsulClient client = new ConsulClient(System.getenv("CONSUL_IP"));
			Response<List<CatalogService>> nodesResponse = client.getCatalogService(serviceName, QueryParams.DEFAULT);
			for (CatalogService c : nodesResponse.getValue()) {
				log.info("Pinging .."+c.toString());
				String ip = c.getServiceAddress();
				try {
					InetAddress inet = InetAddress.getByName(ip);
					boolean reachable = inet.isReachable(5000);
				log.info(ip+ " - " + (reachable ? "reachable" : "unreachable"));
				} catch (IOException e) {
					log.info("Unknown host at "+ip);
				}
			}
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
		}
	}
}
