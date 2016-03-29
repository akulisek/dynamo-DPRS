package sk.stuba.fiit;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;

import org.apache.log4j.Logger;

public class ContextListener implements ServletContextListener {

	private static org.apache.log4j.Logger log = Logger.getLogger(ContextListener.class);
	private CommThread communicateThread = null;

	@Override
	public void contextInitialized(ServletContextEvent arg0) {
		log.info("contextInitialized..");
        if ((communicateThread == null) || (!communicateThread.isAlive())) {
        	communicateThread = new CommThread();
        	communicateThread.start();
        }
		
	}

	@Override
	public void contextDestroyed(ServletContextEvent arg0) {
		log.info("contextDestroyed..");
		try {
			communicateThread.interrupt();
        } catch (Exception ex) {
        }
		
	}

}
