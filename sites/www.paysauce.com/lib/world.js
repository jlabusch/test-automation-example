const {World} = require('@cucumber/cucumber');
const {Builder} = require('selenium-webdriver');
const fs = require('fs');

class PaySauceWorld extends World{
    driver = null;

    constructor(options){
        super(options);
    }

    async setup(){
        this.driver = new Builder()
                .usingServer('http://192.168.1.62:4444')
                .forBrowser('firefox')
                .build();

        await this.driver.manage().window().setRect(1920, 1080);
    }

    async screenshot(filename){
        console.log(`Taking screenshot ${filename}`);

        let image = await this.driver.takeScreenshot();

        fs.writeFileSync('/opt/paysauce-tests/screenshots/' + filename, image, 'base64', err => {
            if (err){
                console.error(`Error: couldn't save screen shot ${filename}: ${err}`);
            }else{
                console.error(`Wrote ${filename}`);
            }
        });
    }

    async teardown(scenario){
        if (scenario.result.status !== 'PASSED'){
            let filename = scenario.pickle.uri;

            if (scenario.pickle.steps.length > 0){
                let step = scenario.pickle.steps[scenario.pickle.steps.length - 1];
                filename = `${filename}-${step.text}`;
            }

            await this.screenshot(`${safe_string(filename)}.png`);
        }

        await this.driver.quit();
    }
}

function safe_string(x){
    return x.replace(/[ \/.:]+/g, '_')
            .replace(new RegExp('"', 'g'), '');
}

module.exports = PaySauceWorld;
