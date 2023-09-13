import ballerina/http;
import ballerina/log;

type CompaniesSearchResult record {
    Company[] results;
    int totalResults;
};

type Address record {
    string street;
    string postCode;
    string city;
};

type Company record {
    string businessId;
    string name;
    string registrationDate;
    string companyForm;    
    Address[] addresses?;
};

type LiferayCompany record {
    string externalReferenceCode;
    string name;
    string registrationDate;
    string companyForm;
    string street?;
    string postCode?;
    string city?;
};

type LiferayResponseEntity record {
    LiferayCompany[] items;
    int totalCount;
};

http:Client avoindata = check new ("https://avoindata.prh.fi/bis/v1");

# Integration with avoindata API
service / on new http:Listener(9092) {

    resource function get company/[string objectDefinitionExternalReferenceCode](http:Request request, int page, int pageSize) returns @http:Cache {maxAge: 15} LiferayResponseEntity|error? {
        string name = request.getQueryParamValue("search") ?: "";
        string searchRequest = string `?totalResults=true&maxResults=${pageSize}&resultsFrom=${(page - 1) * pageSize}&companyRegistrationFrom=2014-02-28&name=${name}`;
        CompaniesSearchResult search = check avoindata->get(searchRequest);

        LiferayCompany[] items = convertCompanies(search);

        LiferayResponseEntity responseEntity = {
            items: items,
            totalCount: search.totalResults
        };

        return responseEntity;
    }

    resource function get company/[string objectDefinitionExternalReferenceCode]/[string externalReferenceCode](http:Request request) returns @http:Cache {maxAge: 15} LiferayCompany|error? {
        CompaniesSearchResult search = check avoindata->get("/".concat(externalReferenceCode));
        Company company = search.results[0];

        LiferayCompany liferayCompany = convertCompany(company);

        return liferayCompany;
    }

}

http:Client proxy = check new ("http://localhost:9092",
    cache = {
        enabled: true, 
        isShared: true,
        policy: "RFC_7234"
    }
);
# Proxy layer to cache avoindata calls (avoindata response headers make them impossible to cache)
service / on new http:Listener(9090) {
    resource function get company/[string objectDefinitionExternalReferenceCode](http:Request request, int page, int pageSize) returns LiferayResponseEntity|error? {
        log:printInfo("Received " + request.rawPath);
        return proxy->get(request.rawPath);
    }

    resource function get company/[string objectDefinitionExternalReferenceCode]/[string externalReferenceCode](http:Request request) returns LiferayCompany|error? {
        return proxy->get(request.rawPath);
    }

};

function convertCompany(Company company) returns LiferayCompany {
    Address[] addresses = (company.addresses ?: []);
    return {
        externalReferenceCode: company.businessId,
        name: company.name,
        companyForm: company.companyForm,
        registrationDate: company.registrationDate,
        street: addresses[0].street,
        postCode: addresses[0].postCode,
        city: addresses[0].city
        };
}

function convertCompanies(CompaniesSearchResult search) returns LiferayCompany[] {

    LiferayCompany[] items = from Company item in search.results
        select {
            externalReferenceCode: item.businessId,
            name: item.name,
            companyForm: item.companyForm,
            registrationDate: item.registrationDate
        };
    return items;
}
