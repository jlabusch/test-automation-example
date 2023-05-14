const assert = require('assert');
const {setWorldConstructor, Before, Given, When, Then, After} = require('@cucumber/cucumber');
const {Builder, By, until} = require('selenium-webdriver');
const PaySauceWorld = require('../../lib/world.js');

var __N = 1;

setWorldConstructor(PaySauceWorld);

Before(async function(){
    this.__n = __N++;

    this.setup();
});

Given("I'm on the homepage", async function(){
    await this.driver.get('https://www.paysauce.com');

    await this.driver.wait(until.elementLocated(By.css('.menu')));
});

When("I navigate to {string}", async function(nav_target){
    this.nav_target = nav_target;

    let link = await this.driver.findElement(By.css(`.menu > a[href='${nav_target}']`));

    await this.driver.executeScript('arguments[0].scrollIntoView()', link);
    await this.driver.executeScript('arguments[0].click()', link);

    let re = new RegExp(`/${nav_target}/$`);

    await this.driver.wait(until.urlMatches(re), 10000, `Nav link didn't go to /${nav_target}/`);

    await this.driver.wait(until.elementLocated(By.css('.menu')));
});

Then('the first H1 on the page should be {string}', async function(expected_h1){
    let h1 = await this.driver.findElement(By.css('h1'));

    let str = await h1.getText();

    assert.equal(str, expected_h1);
});

After(async function(scenario) {
    await this.teardown(scenario);
});
