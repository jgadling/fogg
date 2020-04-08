package v2

import (
	"encoding/json"
	"math/rand"
	"reflect"
)

// Generate is used for test/quick integration. There are supposedly ways to do this without polluting the public
// api, but givent that fogg isn't an api, it doesn't seem like a big deal
func (c *Config) Generate(r *rand.Rand, size int) reflect.Value {
	// TODO write this to be part of tests https://github.com/shiwano/submarine/blob/5c02c0cfcf05126454568ef9624550eb0d84f86c/server/battle/src/battle/util/util_test.go#L19

	conf := &Config{}

	const letterBytes = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

	randString := func(r *rand.Rand, n int) string {
		b := make([]byte, n)
		for i := range b {
			b[i] = letterBytes[r.Intn(len(letterBytes))]
		}
		return string(b)
	}

	randNonEmptyString := func(r *rand.Rand, s int) string {
		return "asdf"
	}

	randStringPtr := func(r *rand.Rand, s int) *string {
		str := randString(r, s)
		return &str
	}

	randBoolPtr := func(r *rand.Rand, s int) *bool {
		b := r.Float32() > 0.5
		return &b
	}
	randIntPtr := func(r *rand.Rand, s int) *int {
		i := r.Intn(s)
		return &i
	}

	randStringMap := func(r *rand.Rand, s int) map[string]string {
		m := map[string]string{}

		for i := 0; i < s; i++ {
			m[randNonEmptyString(r, s)] = randString(r, s)
		}

		return map[string]string{}
	}

	randOktaProvider := func(r *rand.Rand, s int) *OktaProvider {
		if r.Float32() < 0.5 {
			return nil
		}
		return &OktaProvider{
			Version: randStringPtr(r, s),
			OrgName: randStringPtr(r, s),
		}
	}

	randBlessProvider := func(r *rand.Rand, s int) *BlessProvider {
		if r.Float32() < 0.5 {
			return nil
		}
		return &BlessProvider{
			Version:           randStringPtr(r, s),
			AWSRegion:         randStringPtr(r, s),
			AWSProfile:        randStringPtr(r, s),
			AdditionalRegions: []string{randString(r, s)},
		}
	}

	randAWSProvider := func(r *rand.Rand, s int) *AWSProvider {
		if r.Float32() < 0.5 {
			accountID := json.Number(randString(r, s))
			return &AWSProvider{
				AccountID: &accountID,
				Region:    randStringPtr(r, s),
				Profile:   randStringPtr(r, s),
				Version:   randStringPtr(r, s),
			}
		}
		return nil
	}

	randSnowflakeProvider := func(r *rand.Rand, s int) *SnowflakeProvider {
		if r.Float32() < 0.5 {
			return &SnowflakeProvider{
				Account: randStringPtr(r, size),
				Region:  randStringPtr(r, s),
				Role:    randStringPtr(r, s),
			}
		}
		return nil
	}

	randHerokuProvider := func(r *rand.Rand, s int) *HerokuProvider {
		if r.Float32() < 0.5 {
			return &HerokuProvider{}
		}
		return nil
	}

	randDatadogProvider := func(r *rand.Rand, s int) *DatadogProvider {
		if r.Float32() < 0.5 {
			return &DatadogProvider{}
		}
		return nil
	}

	randCommon := func(r *rand.Rand, s int) Common {
		c := Common{
			Backend: &Backend{
				Bucket: randStringPtr(r, s),
				Region: randStringPtr(r, s),
			},
			ExtraVars: randStringMap(r, s),
			Owner:     randStringPtr(r, s),
			Project:   randStringPtr(r, s),
			Providers: &Providers{
				AWS:       randAWSProvider(r, s),
				Snowflake: randSnowflakeProvider(r, s),
				Okta:      randOktaProvider(r, s),
				Bless:     randBlessProvider(r, s),
				Heroku:    randHerokuProvider(r, s),
				Datadog:   randDatadogProvider(r, s),
			},
			TerraformVersion: randStringPtr(r, s),
		}

		if r.Float32() < 0.5 {
			c.Tools = &Tools{}
			if r.Float32() < 0.5 {
				c.Tools.TravisCI = &TravisCI{
					CommonCI: CommonCI{
						Enabled:     randBoolPtr(r, s),
						TestBuckets: randIntPtr(r, s),
					},
				}
			}
			if r.Float32() < 0.5 {
				p := r.Float32() < 0.5
				c.Tools.TfLint = &TfLint{
					Enabled: &p,
				}
			}
		}

		return c
	}

	conf.Version = 2

	conf.Defaults = Defaults{
		Common: randCommon(r, size),
	}

	// tools

	conf.Accounts = map[string]Account{}
	acctN := r.Intn(size)

	for i := 0; i < acctN; i++ {
		acctName := randString(r, size)
		conf.Accounts[acctName] = Account{
			Common: randCommon(r, size),
		}

	}

	conf.Envs = map[string]Env{}
	envN := r.Intn(size)

	for i := 0; i < envN; i++ {
		envName := randString(r, size)
		e := Env{
			Common: randCommon(r, size),
		}
		e.Components = map[string]Component{}
		compN := r.Intn(size)

		for i := 0; i < compN; i++ {
			compName := randString(r, size)
			e.Components[compName] = Component{
				Common: randCommon(r, size),
			}
		}
		conf.Envs[envName] = e

	}

	return reflect.ValueOf(conf)
}
