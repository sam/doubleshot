// This class was lifted from the JBundler project:
// https://github.com/mkristian/jbundler

package org.sam.doubleshot;

import org.apache.maven.wagon.Wagon;
import org.apache.maven.wagon.providers.http.HttpWagon;
import org.sonatype.aether.connector.wagon.WagonProvider;

public class ManualWagonProvider implements WagonProvider {

    public Wagon lookup( String roleHint )
        throws Exception {
        if ( "http".equals( roleHint ) ) {
            return new HttpWagon();
        }
        return null;
    }

    public void release( Wagon wagon ) {

    }

}
