package Zera::AdminSC::Actions;

use strict;
use JSON;
use base 'Zera::BaseAdmin::Actions';

sub do_brands_edit {
    my $self = shift;
    my $results = {};

    $self->param('brand_id',0) if($self->param('brand_id') eq 'New');

    if($self->param('_submit') eq 'Save'){
        # Prevent URL duplicates
        my $exist = $self->selectrow_array(
            "SELECT COUNT(*) FROM sc_brands WHERE name=? AND brand_id<>?",{},$self->param('name'), int($self->param('brand_id'))) || 0;
        if($exist){
            my $base_name = $self->param('name');
            for (my $i = 1; $i < 1000; $i++){
                $self->param('name',$base_name . '-'.$i);
                $exist = $self->selectrow_array(
                    "SELECT COUNT(*) FROM sc_brands WHERE name=? AND brand_id<>?",{},$self->param('name'), int($self->param('brand_id'))) || 0;
                last if ($exist == 0);
            }
        }

        my $image = $self->upload_file('image', 'img');
        eval {
            if(int($self->param('brand_id'))){
                # Update
                $self->dbh_do("UPDATE sc_brands SET name=?, active=?, description=? " .
                                 " WHERE brand_id=?",{},
                                 $self->param('name'), int($self->param('active')), $self->param('description'),$self->param('brand_id'));
               if($image){
                 my $oldimage = $self->selectrow_hashref("SELECT image FROM sc_brands WHERE brand_id = ?", {}, $self->param('brand_id'));
                 $self->add_msg("info", $oldimage->{image});
                 unlink "data/img/$oldimage->{image}" if($oldimage->{image});
                 $self->dbh_do("UPDATE sc_brands SET image=? " .
                                  " WHERE brand_id=?",{},
                                  $image, $self->param('brand_id'));
               }
            }else{
                # Insert
                $self->dbh_do("INSERT INTO sc_brands (name,image, active, description) " .
                                 "VALUES (?,?,?,?)",{},
                                 $self->param('name'), $image, int($self->param('active')), $self->param('description'));
            }
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/Brands';
            $results->{success} = 1;
            return $results;
        }
    }elsif($self->param('_submit') eq 'Delete'){
        eval {
            my $oldimage = $self->selectrow_hashref("SELECT image FROM sc_brands WHERE brand_id = ?", {}, $self->param('brand_id'));
            unlink "data/img/$oldimage->{image}" if($oldimage->{image});
            $self->dbh_do("DELETE FROM sc_brands  WHERE brand_id=?",{},
                             $self->param('brand_id'));
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $self->add_msg("info", 'Brand deleted');
            $results->{redirect} = '/AdminSC/Brands';
            $results->{success} = 1;
            return $results;
        }

    }elsif($self->param('_submit') eq 'Delete Logo'){
        eval {
            my $oldimage = $self->selectrow_hashref("SELECT image FROM sc_brands WHERE brand_id = ?", {}, $self->param('brand_id'));
            $self->add_msg("info", $oldimage->{image});
            unlink "data/img/$oldimage->{image}" if($oldimage->{image});
            $self->dbh_do("UPDATE sc_brands  SET image='' WHERE brand_id=?",{},
                             $self->param('brand_id'));
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/BrandsEdit/'.$self->param('brand_id');
            $results->{success} = 1;
            return $results;
        }
    }
}

sub do_options_edit {
    my $self = shift;
    my $results = {};

    $self->param('option_id',0) if($self->param('option_id') eq 'New');

    if($self->param('_submit') eq 'Save'){
        eval {
            if(int($self->param('option_id'))){
                # Update
                $self->dbh_do(  "UPDATE sc_options SET option=? " .
                                "WHERE option_id=?",{},
                                $self->param('option'), $self->param('option_id'));
            }else{
                # Insert
                $self->dbh_do("INSERT INTO sc_options (option) " .
                                 "VALUES (?)",{},
                                 $self->param('option'));
            }
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/Options';
            $results->{success} = 1;
            return $results;
        }
    }elsif($self->param('_submit') eq 'Delete'){
        eval {
            $self->dbh_do(
                "DELETE FROM sc_options_values WHERE option_id=?",{}, $self->param('option_id'));
            $self->dbh_do("DELETE FROM sc_options WHERE option_id=?",{}, $self->param('option_id'));
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/Options';
            $results->{success} = 1;
            return $results;
        }
    }
}

sub do_option_details {
    my $self = shift;
    my $results = {};

    $self->param('option_id',0) if($self->param('option_id') eq 'New');

    if($self->param('_submit') eq 'Save'){
        eval {
            if(int($self->param('value_id'))){
                # Update
                $self->dbh_do(
                    "UPDATE sc_options_values SET option_value=? " .
                    "WHERE value_id=? AND option_id=?",{},
                    $self->param('option_value'), $self->param('value_id'),$self->param('option_id'));
            }else{
                # Insert
                $self->dbh_do(
                    "INSERT INTO sc_options_values (option_id, option_value) " .
                    "VALUES (?,?)",{},
                    $self->param('option_id'), $self->param('option_value'));
            }
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/OptionDetails/' . $self->param('option_id');
            $results->{success} = 1;
            return $results;
        }
    }elsif($self->param('_submit') eq 'Delete'){
        eval {
            $self->dbh_do(
                "DELETE FROM sc_options_values WHERE value_id=? AND option_id=?",{},
                $self->param('value_id'), $self->param('option_id'));
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/OptionDetails/' . $self->param('option_id');
            $results->{success} = 1;
            return $results;
        }
    }
}

sub do_category_edit {
    my $self = shift;
    my $results = {};

    $self->param('category_id',0) if($self->param('category_id') eq 'New');

    if($self->param('_submit') eq 'Save'){
        # Prevent duplicated urls
        my $exist = $self->selectrow_array(
            "SELECT COUNT(*) FROM sc_categories WHERE url=? AND category_id<>?",{},$self->param('url'), int($self->param('category_id'))) || 0;
        if($exist){
            my $base_name = $self->param('url');
            for (my $i = 1; $i < 1000; $i++){
                $self->param('url',$base_name . '-'.$i);
                $exist = $self->selectrow_array(
                    "SELECT COUNT(*) FROM sc_categories WHERE url=? AND category_id<>?",{},$self->param('url'), int($self->param('category_id'))) || 0;
                last if ($exist == 0);
            }
        }

        my $image = $self->upload_file('image', 'category');
        if($image){
            # Generate Thumbnail
            $self->create_thumbnail('category/'.$image, 'category_thumb/'.$image,'300x300');
        }
        eval {
            if(int($self->param('category_id'))){
                $self->dbh_do("UPDATE sc_categories SET name=?, url=?, active=?, description=?, sort_order=?, details=? " .
                    "WHERE category_id=?",{},
                    $self->param('name'), $self->param('url'), int($self->param('active')), $self->param('description'),
                    $self->param('sort_order'), $self->param('details'), $self->param('category_id'));
               if($image){
                 my $oldimage = $self->selectrow_hashref("SELECT image FROM sc_categories WHERE category_id = ?", {}, $self->param('category_id'));
                 unlink "data/category/$oldimage->{image}" if($oldimage->{image});
                 unlink "data/category_thumb/$oldimage->{image}" if($oldimage->{image});
                 $self->dbh_do("UPDATE sc_categories SET image=? WHERE category_id=?",{},
                    $image, $self->param('category_id'));
               }
            }else{
                # Insert
                $self->dbh_do("INSERT INTO sc_categories (parent_id, name, url, image, active, description, sort_order, details) " .
                    "VALUES (?,?,?,?,?,?,?,?)",{},
                    $self->param('parent_id'), $self->param('name'), $self->param('url'), $image, int($self->param('active')),
                    $self->param('description'), $self->param('sort_order'), $self->param('details'));
            }
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/Categories';
            $results->{success} = 1;
            return $results;
        }
    }elsif($self->param('_submit') eq 'Delete'){
        eval {
            my $oldimage = $self->selectrow_hashref("SELECT image FROM sc_categories WHERE category_id = ?", {},
                $self->param('category_id'));
                unlink "data/category/$oldimage->{image}" if($oldimage->{image});
                unlink "data/category_thumb/$oldimage->{image}" if($oldimage->{image});
            $self->dbh_do("DELETE FROM sc_categories  WHERE category_id=?",{}, $self->param('category_id'));
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $self->add_msg("info", 'Category deleted');
            $results->{redirect} = '/AdminSC/Categories';
            $results->{success} = 1;
            return $results;
        }
    }elsif($self->param('_submit') eq 'Delete Image'){
        eval {
            my $oldimage = $self->selectrow_hashref("SELECT image FROM sc_categories WHERE category_id = ?", {}, $self->param('category_id'));
            unlink "data/category/$oldimage->{image}" if($oldimage->{image});
            unlink "data/category_thumb/$oldimage->{image}" if($oldimage->{image});
            $self->dbh_do("UPDATE sc_categories  SET image='' WHERE category_id=?",{}, $self->param('category_id'));
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/CategoryEdit/'.$self->param('category_id');
            $results->{success} = 1;
            return $results;
        }
    }
}

sub do_category_child {
    my $self = shift;
    my $results = {};

    $self->param('category_id',0) if(!$self->param('category_id'));

    if($self->param('_submit') eq 'Save'){
        # Prevent duplicated urls
        my $exist = $self->selectrow_array(
            "SELECT COUNT(*) FROM sc_categories WHERE url=? AND category_id<>?",{},$self->param('url'), int($self->param('category_id'))) || 0;
        if($exist){
            my $base_name = $self->param('url');
            for (my $i = 1; $i < 1000; $i++){
                $self->param('url',$base_name . '-'.$i);
                $exist = $self->selectrow_array(
                    "SELECT COUNT(*) FROM sc_categories WHERE url=? AND category_id<>?",{},$self->param('url'), int($self->param('category_id'))) || 0;
                last if ($exist == 0);
            }
        }

        my $image = $self->upload_file('image', 'category');
        if($image){
            # Generate Thumbnail
            $self->create_thumbnail('category/'.$image, 'category_thumb/'.$image,'300x300');
        }
        eval {
            if(int($self->param('category_id'))){
                $self->dbh_do("UPDATE sc_categories SET name=?, url=?, active=?, description=?, sort_order=?, details=? " .
                    "WHERE category_id=?",{},
                    $self->param('name'), $self->param('url'), int($self->param('active')), $self->param('description'),
                    $self->param('sort_order'), $self->param('details'), $self->param('category_id'));
               if($image){
                 my $oldimage = $self->selectrow_hashref("SELECT image FROM sc_categories WHERE category_id = ?", {}, $self->param('category_id'));
                 unlink "data/category/$oldimage->{image}" if($oldimage->{image});
                 unlink "data/category_thumb/$oldimage->{image}" if($oldimage->{image});
                 $self->dbh_do("UPDATE sc_categories SET image=? WHERE category_id=?",{},
                    $image, $self->param('category_id'));
               }
            }else{
                # Insert
                $self->dbh_do("INSERT INTO sc_categories (parent_id, name, url, image, active, description, sort_order, details) " .
                    "VALUES (?,?,?,?,?,?,?,?)",{},
                    $self->param('parent_id'), $self->param('name'), $self->param('url'), $image, int($self->param('active')),
                    $self->param('description'), $self->param('sort_order'), $self->param('details'));
            }
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/Categories';
            $results->{success} = 1;
            return $results;
        }
    }elsif($self->param('_submit') eq 'Delete'){
        eval {
            my $oldimage = $self->selectrow_hashref("SELECT image FROM sc_categories WHERE category_id = ?", {},
                $self->param('category_id'));
                unlink "data/category/$oldimage->{image}" if($oldimage->{image});
                unlink "data/category_thumb/$oldimage->{image}" if($oldimage->{image});
            $self->dbh_do("DELETE FROM sc_categories  WHERE category_id=?",{}, $self->param('category_id'));
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $self->add_msg("info", 'Category deleted');
            $results->{redirect} = '/AdminSC/Categories';
            $results->{success} = 1;
            return $results;
        }
    }elsif($self->param('_submit') eq 'Delete Image'){
        eval {
            my $oldimage = $self->selectrow_hashref("SELECT image FROM sc_categories WHERE category_id = ?", {}, $self->param('category_id'));
            unlink "data/category/$oldimage->{image}" if($oldimage->{image});
            unlink "data/category_thumb/$oldimage->{image}" if($oldimage->{image});
            $self->dbh_do("UPDATE sc_categories  SET image='' WHERE category_id=?",{}, $self->param('category_id'));
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/CategoryEdit/'.$self->param('category_id');
            $results->{success} = 1;
            return $results;
        }
    }
}

sub do_products_edit {
    my $self = shift;
    my $results = {};

    if($self->param('_submit') eq 'Save'){
        my $image = $self->upload_file('image', 'products');
        if($image){
            # Generate Thumbnail
            $self->create_thumbnail('products/'.$image, 'products_thumb/'.$image,'300x300');
        }

        eval {
            if(int($self->param('product_id'))){
                $self->dbh_do("UPDATE sc_products SET code=?, name=?, keywords=?, active=?, option_id=?, brand_id=? " .
                    "WHERE product_id=?",{},
                    $self->param('code'), $self->param('name'), $self->param('keywords'), ($self->param('active') || 0), $self->param('option_id'),
                    $self->param('brand_id'), $self->param('product_id'));
               if($image){
                 my $oldimage = $self->selectrow_hashref("SELECT image FROM sc_products WHERE product_id = ?", {}, $self->param('product_id'));
                 unlink "data/products/$oldimage->{image}" if($oldimage->{image});
                 unlink "data/products_thumb/$oldimage->{image}" if($oldimage->{image});
                 $self->dbh_do("UPDATE sc_products SET image=? WHERE product_id=?",{}, $image, $self->param('product_id'));
               }
            }else{
                $self->dbh_do("INSERT INTO sc_products (code, name, keywords, image, active, option_id, brand_id) " .
                    "VALUES (?,?,?,?,?,?,?)",{},
                    $self->param('code'), $self->param('name'), $self->param('keywords'), $image, ($self->param('active') || 0), $self->param('option_id'),
                    $self->param('brand_id'));
            }
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/Products';
            $results->{success} = 1;
            return $results;
        }
    }elsif($self->param('_submit') eq 'Delete'){
        eval {
            my $oldimage = $self->selectrow_hashref("SELECT image FROM sc_products WHERE product_id = ?", {}, $self->param('product_id'));
            unlink "data/products/$oldimage->{image}" if($oldimage->{image});
            unlink "data/products_thumb/$oldimage->{image}" if($oldimage->{image});
            $self->dbh_do("DELETE FROM sc_products WHERE product_id=?",{}, $self->param('product_id'));
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/Products';
            $results->{success} = 1;
            return $results;
        }
    }
}

sub do_products_categories {
    my $self = shift;
    my $results = {};

    if($self->param('_submit') eq 'Save'){
        eval {
            # Delete all relations
            $self->dbh_do("DELETE FROM sc_products_to_categories WHERE product_id=?",{},$self->param('product_id'));

            # Create selected relations
            my $categories = $self->selectall_arrayref("SELECT category_id FROM sc_categories",{Slice=>{}});
            foreach my $category (@$categories) {
                if($self->param('cat_' . $category->{category_id})){
                    $self->dbh_do("INSERT INTO sc_products_to_categories (product_id, category_id) VALUES (?,?) ",{},
                        $self->param('product_id'), $category->{category_id});
                }
            }
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/ProductsEdit/'.$self->param('product_id');
            $results->{success} = 1;
            return $results;
        }
    }
}

sub do_products_gallery {
    my $self = shift;
    my $results = {};

    if($self->param('_submit') eq 'Save'){
        eval {
            if(!(int($self->param('image_id')))){
                my $image = $self->upload_file('image', 'pg');
                if($image){
                    # Generate Thumbnails
                    $self->create_thumbnail('pg/'.$image, 'pg/'.$image,'1200x1200');
                    $self->create_thumbnail('pg/'.$image, 'pg600/'.$image,'600x600');
                    $self->create_thumbnail('pg/'.$image, 'pg300/'.$image,'300x300');
                    $self->create_thumbnail('pg/'.$image, 'pg150/'.$image,'150x150');
                }else{
                    $self->add_msg('warning','Please choose a image for the product gallery');
                    $results->{error} = 1;
                    return $results;
                }
                $self->dbh_do("INSERT INTO sc_products_images (product_id, image, description, sort_order) VALUES (?,?,?,?) ",{},
                    $self->param('product_id'), $image, $self->param('description'), $self->param('sort_order'));
            }else{
                $self->dbh_do("UPDATE sc_products_images SET description=?, sort_order=? WHERE image_id=? ",{},
                    $self->param('description'), $self->param('sort_order'), $self->param('image_id'));
            }
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/ProductsGallery/'.$self->param('product_id');
            $results->{success} = 1;
            return $results;
        }
    }elsif($self->param('_submit') eq 'Delete'){
        eval {
            my $oldimage = $self->selectrow_hashref("SELECT image FROM sc_products_images WHERE image_id= ?", {},
                $self->param('image_id'));
                unlink "data/pg/$oldimage->{image}" if($oldimage->{image});
                unlink "data/pg600/$oldimage->{image}" if($oldimage->{image});
                unlink "data/pg300/$oldimage->{image}" if($oldimage->{image});
                unlink "data/pg150/$oldimage->{image}" if($oldimage->{image});
            $self->dbh_do("DELETE FROM sc_products_images WHERE image_id=?",{}, $self->param('image_id'));
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/ProductsGallery/'. $self->param('product_id');
            $results->{success} = 1;
            return $results;
        }
    }
}

sub do_add_related {
    my $self = shift;
    my $results = {};

    $self->param('product_id',$self->param('SubView')) if(!($self->param('product_id')));

    eval {
        $self->dbh_do("INSERT IGNORE INTO sc_related_products (product_id, product_related_id) VALUES (?,?) ",{},
            $self->param('product_id'), $self->param('id'));
        $self->dbh_do("INSERT IGNORE INTO sc_related_products (product_id, product_related_id) VALUES (?,?) ",{},
            $self->param('id'), $self->param('product_id'));
    };
    if($@){
        $self->add_msg('warning','Error '.$@);
        $results->{error} = 1;
        return $results;
    }else{
        $results->{redirect} = '/AdminSC/ProductsRelated/'.$self->param('product_id') . '?zl_q='.$self->param('zl_q');
        $results->{success} = 1;
        return $results;
    }
}

sub do_remove_related {
    my $self = shift;
    my $results = {};

    $self->param('product_id',$self->param('SubView')) if(!($self->param('product_id')));

    eval {
        $self->dbh_do("DELETE FROM sc_related_products WHERE product_id=? AND product_related_id=? ",{},
            $self->param('product_id'), $self->param('id'));
        $self->dbh_do("DELETE FROM sc_related_products WHERE product_id=? AND product_related_id=? ",{},
            $self->param('id'), $self->param('product_id'));
    };
    if($@){
        $self->add_msg('warning','Error '.$@);
        $results->{error} = 1;
        return $results;
    }else{
        $results->{redirect} = '/AdminSC/ProductsRelated/'.$self->param('product_id') . '?zl_q='.$self->param('zl_q');
        $results->{success} = 1;
        return $results;
    }
}

sub do_add_complementary {
    my $self = shift;
    my $results = {};

    $self->param('product_id',$self->param('SubView')) if(!($self->param('product_id')));

    eval {
        $self->dbh_do("INSERT IGNORE INTO sc_complementary_products (product_id, product_complementary_id) VALUES (?,?) ",{},
            $self->param('product_id'), $self->param('id'));
        $self->dbh_do("INSERT IGNORE INTO sc_complementary_products (product_id, product_complementary_id) VALUES (?,?) ",{},
            $self->param('id'), $self->param('product_id'));
    };
    if($@){
        $self->add_msg('warning','Error '.$@);
        $results->{error} = 1;
        return $results;
    }else{
        $results->{redirect} = '/AdminSC/ProductsComplementary/'.$self->param('product_id') . '?zl_q='.$self->param('zl_q');
        $results->{success} = 1;
        return $results;
    }
}

sub do_remove_complementary {
    my $self = shift;
    my $results = {};

    $self->param('product_id',$self->param('SubView')) if(!($self->param('product_id')));

    eval {
        $self->dbh_do("DELETE FROM sc_complementary_products WHERE product_id=? AND product_complementary_id=? ",{},
            $self->param('product_id'), $self->param('id'));
        $self->dbh_do("DELETE FROM sc_complementary_products WHERE product_id=? AND product_complementary_id=? ",{},
            $self->param('id'), $self->param('product_id'));
    };
    if($@){
        $self->add_msg('warning','Error '.$@);
        $results->{error} = 1;
        return $results;
    }else{
        $results->{redirect} = '/AdminSC/ProductsComplementary/'.$self->param('product_id') . '?zl_q='.$self->param('zl_q');
        $results->{success} = 1;
        return $results;
    }
}

1;
