const BaseCommand = require('../../lib/BaseCommand');
const yaml = require('js-yaml');
const fs = require('fs-jetpack');
const path = require('path');
const log = require('../../lib/logger');

class selectResources extends BaseCommand {

    /**
     * Put symlinks for selected resources
     *
     * @param {any} dir
     * @param {any} resources
     * @returns
     */
    selectResources(dir, resources) {
        // console.log(fs.list(dir));

        fs.dir(dir); // create dir if necessary
        fs.list(dir)
            .filter(file => file !== '.keep')
            .forEach(file => fs.remove(`${dir}/${file}`));

        if (resources && resources.length) {
            resources.forEach((file) => {
                const src = path.resolve(`${dir}_available/${file}`);
                const dest = path.resolve(`${dir}/${file}`);

                if (fs.exists(src)) {
                    fs.symlink(src, dest);
                    log.info(`Selected ${dir}: ${dir}/${file}`);
                } else {
                    log.error(`${dir}_available/${file} doesn't exists`);
                }
            });
        }
    }

    /**
     * Run resources selection
     *
     */
    run() {
        try {
            // console.log(process.cwd());
            // console.log(yaml.safeLoad(fs.read('resources.yml')));
            const { contracts, migrations, test } = yaml.safeLoad(fs.read('resources.yml'));

            this.selectResources('contracts', contracts);
            this.selectResources('migrations', migrations);
            this.selectResources('test', test);
        } catch (e) {
            log.error(e);
        }
    }

}

module.exports = selectResources;
