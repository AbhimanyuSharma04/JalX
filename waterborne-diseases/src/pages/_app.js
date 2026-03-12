import '../index.css';
import '../Dashboard.css';
import '../MobileWaterData.css';
import '../Components/SafetyScaleCustom.css';
import 'bootstrap/dist/css/bootstrap.min.css';
import 'leaflet/dist/leaflet.css';
import '../i18n';
import Head from 'next/head';

function MyApp({ Component, pageProps }) {
    return (
        <>
            <Head>
                <title>Jal-Rakshak: Disease Outbreak Monitor</title>
                <meta name="viewport" content="width=device-width, initial-scale=1" />
            </Head>
            <Component {...pageProps} />
        </>
    );
}

export default MyApp;
